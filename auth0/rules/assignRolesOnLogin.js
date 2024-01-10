function assignRolesOnLogin(user, context, callback) {
    // This rule does not apply to unverified users - never assign a privileged role without verification!
    if (!user.email || !user.email_verified) {
        return callback(null, user, context);
    }

    const maybeEmailDomain = 'maybe.co';
    const emailSplit = user.email.split('@');
    const isMaybeEmployee = emailSplit[emailSplit.length - 1].toLowerCase() === maybeEmailDomain;

    if (!isMaybeEmployee) {
        return callback(null, user, context);
    }

    // Use latest version that is allowed here - https://auth0-extensions.github.io/canirequire/#auth0
    const ManagementClient = require('auth0@2.35.0').ManagementClient;

    const cli = new ManagementClient({
        token: auth0.accessToken,
        domain: auth0.domain,
    });

    const admins = ['REPLACE_THIS'];

    const rolesToAssign = [];

    // https://auth0.com/docs/rules/configuration#use-the-configuration-object
    if (admins.includes(user.email)) {
        rolesToAssign.push(configuration.ADMIN_ROLE_ID);
    }

    // https://auth0.com/docs/rules/configuration#use-the-configuration-object
    if (isMaybeEmployee) {
        rolesToAssign.push(configuration.BETA_TESTER_ROLE_ID);
    }

    // If we make it here, we know the user has verified their email and their email is in the Maybe Finance Gmail domain
    cli.assignRolestoUser({ id: user.user_id }, { roles: rolesToAssign }, function (err) {
        if (err) {
            console.log(err);
        }

        return callback(null, user, context);
    });
}
