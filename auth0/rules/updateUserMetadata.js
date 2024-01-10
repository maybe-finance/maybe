function updateUserMetadata(user, context, callback) {
    // Use latest version that is allowed here (2.4.0 as of today) - https://auth0-extensions.github.io/canirequire/#auth0
    const ManagementClient = require('auth0@2.35.0').ManagementClient;

    const cli = new ManagementClient({
        token: auth0.accessToken,
        domain: auth0.domain,
    });

    const metadata = {
        firstName:
            (user.user_metadata && user.user_metadata.firstName) ||
            user.first_name ||
            user.given_name ||
            '',
        lastName:
            (user.user_metadata && user.user_metadata.lastName) ||
            user.last_name ||
            user.family_name ||
            '',
    };

    // Maps data from various identity providers to a normalized identity
    cli.updateUserMetadata({ id: user.user_id }, metadata, function (err, updatedUser) {
        return callback(null, updatedUser, context);
    });
}
