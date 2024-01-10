// https://auth0.com/docs/secure/multi-factor-authentication/customize-mfa
function mfaAuth(user, context, callback) {
    const ENABLED_CLIENT_IDS = [
        'REPLACE_THIS',
    ];

    // Only enable MFA on the Next.js app (client IDs above)
    if (ENABLED_CLIENT_IDS.indexOf(context.clientID) !== -1) {
        // This makes MFA optional for users (they can enroll via their profile within the app)
        if (user.user_metadata && user.user_metadata.enrolled_mfa) {
            context.multifactor = {
                // See options here - https://auth0.com/docs/secure/multi-factor-authentication/customize-mfa#use-rules
                // `any` is the generic option (i.e. Google Authenticator or something similar)
                provider: 'any',

                // If set to true, MFA will turn off for 30 days for the user's current browser
                allowRememberBrowser: true,
            };
        }
    }

    return callback(null, user, context);
}
