const { config, sync } = require('./config')

const firstArg = process.argv.slice(2)[0]

if (firstArg === '--force') {
    sync({
        config: {
            ...config,

            // The deploy client only works with the DEFAULT Auth0 domain, NOT with custom domains
            AUTH0_DOMAIN: config.AUTH0_KEYWORD_REPLACE_MAPPINGS.AUTH0_DOMAIN,
        },
        format: 'yaml',
        output_folder: __dirname,
    })
        .then(() =>
            console.log(
                `Synced ${config.AUTH0_KEYWORD_REPLACE_MAPPINGS.AUTH0_DOMAIN} successfully!`
            )
        )
        .catch((err) => console.log(`Sync failed: ${err}`))
} else {
    console.log(
        'Syncing not recommended (see README.md).  Instead, you should make changes locally and deploy to the tenant.  \n\nIf you are sure you want to do this, run: \n\n`node sync --force`\n'
    )
}
