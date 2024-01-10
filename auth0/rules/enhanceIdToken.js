function enhanceIdToken(user, context, callback) {
    // Does not have to be a valid URL, just has to be unique and start with http / https
    const namespace = 'https://maybe.co';

    const assignedRoles = (context.authorization || {}).roles;

    let idTokenClaims = context.idToken || {};
    let accessTokenClaims = context.accessToken || {};

    let identityClaim;

    if (user.identities && user.identities.length) {
        const primaryIdentities = user.identities.filter((identity) => {
            // https://auth0.com/docs/manage-users/user-accounts/user-account-linking#how-it-works
            const isSecondary = 'profileData' in identity;

            return !isSecondary;
        });

        if (primaryIdentities.length === 0) {
            identityClaim = undefined;
        }

        // Based on prior checks, this should represent the primary identity
        const primaryIdentity = primaryIdentities[0];

        identityClaim = {
            connection: primaryIdentity.connection,
            provider: primaryIdentity.provider,
            isSocial: primaryIdentity.isSocial,
        };
    }

    // Access token claims are populated on the parsed server-side JWT
    accessTokenClaims[`${namespace}/name`] = user.name;
    accessTokenClaims[`${namespace}/email`] = user.email;
    accessTokenClaims[`${namespace}/picture`] = user.picture;
    accessTokenClaims[`${namespace}/roles`] = assignedRoles;
    accessTokenClaims[`${namespace}/user-metadata`] = user.user_metadata;
    accessTokenClaims[`${namespace}/app-metadata`] = user.app_metadata;
    accessTokenClaims[`${namespace}/primary-identity`] = identityClaim;

    // ID token claims are populated in the parsed client-side React hook
    idTokenClaims[`${namespace}/roles`] = assignedRoles;
    idTokenClaims[`${namespace}/user-metadata`] = user.user_metadata;
    idTokenClaims[`${namespace}/app-metadata`] = user.app_metadata;
    idTokenClaims[`${namespace}/primary-identity`] = identityClaim;

    context.idToken = idTokenClaims;
    context.accessToken = accessTokenClaims;

    return callback(null, user, context);
}
