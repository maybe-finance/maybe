import type { Institution, PrismaClient, Provider, ProviderInstitution } from '@prisma/client'
import type { Logger } from 'winston'
import type { PgService } from '@maybe-finance/server/shared'
import type { IInstitutionProviderFactory } from './institution.provider'
import { Prisma } from '@prisma/client'
import _ from 'lodash'
import { SharedType } from '@maybe-finance/shared'
import { join, sql } from '@maybe-finance/server/shared'

export interface IInstitutionService {
    getAll(options: { query?: string; page?: number }): Promise<SharedType.InstitutionsResponse>
    sync(provider: Provider): Promise<void>
    deduplicateInstitutions(): Promise<void>
}

export class InstitutionService implements IInstitutionService {
    constructor(
        private readonly logger: Logger,
        private readonly prisma: PrismaClient,
        private readonly pg: PgService,
        private readonly providers: IInstitutionProviderFactory
    ) {}

    async getAll({
        query,
        page = 0,
    }: {
        query?: string
        page?: number
    } = {}): Promise<SharedType.InstitutionsResponse> {
        if (!query) {
            // filter for institutions with at least one provider
            const institutionWhere: Prisma.InstitutionWhereInput = {
                providers: { some: {} },
            }

            // filter for provider institutions not attached to an institution
            const providerInstitutionWhere: Prisma.ProviderInstitutionWhereInput = {
                institution: null,
            }

            const [institutions, institutionCount, providerInstitutions, providerInstitutionCount] =
                await this.prisma.$transaction([
                    this.prisma.institution.findMany({
                        where: institutionWhere,
                        include: {
                            providers: {
                                select: {
                                    id: true,
                                    provider: true,
                                    providerId: true,
                                    rank: true,
                                },
                                orderBy: { rank: 'desc', oauth: 'desc' },
                            },
                        },
                        orderBy: { name: 'asc' },
                        skip: page * SharedType.PageSize.Institution,
                        take: SharedType.PageSize.Institution,
                    }),
                    this.prisma.institution.count({ where: institutionWhere }),
                    this.prisma.providerInstitution.findMany({
                        where: providerInstitutionWhere,
                        orderBy: { name: 'asc' },
                        skip: page * SharedType.PageSize.Institution,
                        take: SharedType.PageSize.Institution,
                    }),
                    this.prisma.providerInstitution.count({ where: providerInstitutionWhere }),
                ])

            return {
                institutions: [
                    ...institutions,
                    ...providerInstitutions.map((pi) => ({
                        id: `provider[${pi.id}]`,
                        name: pi.name,
                        url: pi.url,
                        logo: pi.logo,
                        logoUrl: pi.logoUrl,
                        primaryColor: pi.primaryColor,
                        providers: [
                            {
                                id: pi.id,
                                provider: pi.provider,
                                providerId: pi.providerId,
                                rank: pi.rank,
                            },
                        ],
                    })),
                ],
                totalInstitutions: institutionCount + providerInstitutionCount,
            }
        }

        // autocomplete/search using postgres full-text search
        const tokens = query
            .trim()
            .split(/\s+/gim) // remove whitespace
            .map((x) => x.replace(/\W/gim, '')) // remove non-word characters
            .filter((x) => x.length > 0)
            .map((x) => `${x}:*`) // convert to prefix search query
        this.logger.debug(`converted query: "${query}" to tokens: ${JSON.stringify(tokens)}`)

        const q = Prisma.sql`(${Prisma.join(
            tokens.map((token) => Prisma.sql`to_tsquery('simple', ${token})`),
            ' && '
        )})`

        type InstitutionQueryResult = (Pick<
            Institution,
            'id' | 'name' | 'url' | 'logo' | 'logoUrl' | 'primaryColor'
        > & {
            providers: Pick<ProviderInstitution, 'id' | 'provider' | 'providerId' | 'rank'>[]
        })[]

        const institutionSearchQuery = Prisma.sql`
          SELECT
            i.id,
            i.name,
            i.url,
            i.logo,
            i.logo_url AS "logoUrl",
            i.primary_color AS "primaryColor",
            jsonb_agg(jsonb_build_object('id', pi.id, 'provider', pi.provider, 'providerId', pi.provider_id, 'rank', pi.rank) ORDER BY pi.rank, pi.oauth DESC) AS providers
          FROM
            institution i
            INNER JOIN provider_institution pi ON pi.institution_id = i.id
          WHERE
            edge_ngram_tsvector(i.name) @@ ${q}
            AND pi.rank >= 0
          GROUP BY
            i.id
          ORDER BY
            ts_rank(edge_ngram_tsvector(i.name), ${q}, 1|16) DESC, length(i.name) ASC
        `

        const providerInstitutionSearchQuery = Prisma.sql`
          SELECT
            'provider.' || pi.id AS id,
            pi.name,
            pi.url,
            pi.logo,
            pi.logo_url AS "logoUrl",
            pi.primary_color AS "primaryColor",
            jsonb_build_array(jsonb_build_object('id', pi.id, 'provider', pi.provider, 'providerId', pi.provider_id, 'rank', pi.rank)) AS providers
          FROM
            provider_institution pi
          WHERE
            pi.institution_id IS NULL
            AND edge_ngram_tsvector(pi.name) @@ ${q}
            AND pi.rank >= 0
          ORDER BY
            ts_rank(edge_ngram_tsvector(pi.name), ${q}, 1|16) DESC, length(pi.name) ASC
        `

        const [institutions, [{ count: institutionCount }], [{ count: providerInstitutionCount }]] =
            await this.prisma.$transaction([
                this.prisma.$queryRaw<InstitutionQueryResult>`
                  ${institutionSearchQuery}
                  LIMIT ${SharedType.PageSize.Institution}
                  OFFSET ${page * SharedType.PageSize.Institution};
                `,
                this.prisma.$queryRaw<
                    [{ count: bigint }]
                >`SELECT COUNT(*) FROM (${institutionSearchQuery}) q`,
                this.prisma.$queryRaw<
                    [{ count: bigint }]
                >`SELECT COUNT(*) FROM (${providerInstitutionSearchQuery}) q`,
            ])

        const providerInstitutions =
            institutions.length < SharedType.PageSize.Institution
                ? await this.prisma.$queryRaw<InstitutionQueryResult>`
                    ${providerInstitutionSearchQuery}
                    LIMIT ${SharedType.PageSize.Institution - institutions.length}
                    OFFSET ${Math.max(
                        0,
                        page * SharedType.PageSize.Institution - Number(institutionCount)
                    )};
                  `
                : []

        return {
            institutions: [...institutions, ...providerInstitutions],
            totalInstitutions: Number(institutionCount + providerInstitutionCount),
        }
    }

    async sync(provider: Provider) {
        const institutions = await this.providers.for(provider).getInstitutions()
        this.logger.info(`fetched ${institutions.length} institutions for provider ${provider}`)

        for (const chunk of _.chunk(institutions, 2000)) {
            await this.pg.pool.query(
                sql`
                    INSERT INTO provider_institution (provider, provider_id, name, url, logo, logo_url, primary_color, oauth, data)
                    VALUES
                      ${join(
                          chunk.map(
                              (institution) => sql`(
                                  ${provider},
                                  ${institution.providerId},
                                  ${institution.name},
                                  ${institution.url},
                                  ${institution.logo},
                                  ${institution.logoUrl},
                                  ${institution.primaryColor},
                                  ${institution.oauth},
                                  ${institution.data as any}
                              )`
                          )
                      )}
                    ON CONFLICT (provider, provider_id) DO UPDATE
                    SET
                      name = EXCLUDED.name,
                      url = EXCLUDED.url,
                      logo = EXCLUDED.logo,
                      logo_url = EXCLUDED.logo_url,
                      primary_color = EXCLUDED.primary_color,
                      oauth = EXCLUDED.oauth,
                      data = EXCLUDED.data;
                `
            )
        }

        await this.pg.pool.query(sql`
          DELETE FROM provider_institution
          WHERE
            provider = ${provider}
            AND provider_id NOT IN (${join(institutions.map((i) => i.providerId))})
        `)
    }

    async deduplicateInstitutions() {
        await this.prisma.$executeRaw`
          WITH duplicates AS (
            SELECT
              MAX(TRIM(pi.name)) AS name,
              x.url,
              array_agg(pi.id) AS provider_ids
            FROM
              provider_institution pi
              LEFT JOIN LATERAL (
                SELECT 'https://' || LOWER(TRIM(SPLIT_PART(pi.url, '://', 2))) AS url
              ) x ON true
            GROUP BY
              UPPER(TRIM(pi.name)),
              x.url
            HAVING
              COUNT(pi.id) > 1 AND COUNT(pi.institution_id) < COUNT(pi.id)
          ), institutions AS (
            INSERT INTO institution (name, url, logo, logo_url, primary_color)
            SELECT
              name,
              url,
              (SELECT logo FROM provider_institution pi WHERE pi.id = ANY(provider_ids) AND logo IS NOT NULL LIMIT 1),
              (SELECT logo_url FROM provider_institution pi WHERE pi.id = ANY(provider_ids) AND logo_url IS NOT NULL LIMIT 1),
              (SELECT primary_color FROM provider_institution pi WHERE pi.id = ANY(provider_ids) AND primary_color IS NOT NULL LIMIT 1)
            FROM
              duplicates
            ON CONFLICT (name, url) DO UPDATE
            SET
              name = EXCLUDED.name,
              url = EXCLUDED.url,
              logo = EXCLUDED.logo,
              logo_url = EXCLUDED.logo_url,
              primary_color = EXCLUDED.primary_color
            RETURNING id, name, url
          )
          UPDATE
            provider_institution pi
          SET
            institution_id = i.id,
            rank = (CASE WHEN pi.provider = 'TELLER' THEN 1 ELSE 0 END)
          FROM
            duplicates d
            INNER JOIN institutions i ON i.name = d.name AND i.url = d.url
          WHERE
            pi.id = ANY(d.provider_ids)
            AND pi.institution_id IS NULL;
        `
    }
}
