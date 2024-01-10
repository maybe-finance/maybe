// If the user successfully performs a password reset, we *know* their email is valid, so go ahead and verify it if not already verified
function verifyUserWithPasswordReset(user, context, callback) {
    const request = require('request');
    const userApiUrl = auth0.baseUrl + '/users/';

    // This rule is only for Auth0 databases
    if (context.connectionStrategy !== 'auth0') {
        return callback(null, user, context);
    }

    if (user.email_verified || !user.last_password_reset) {
        return callback(null, user, context);
    }

    // Set email verified if a user has already updated his/her password
    request.patch(
        {
            url: userApiUrl + user.user_id,
            headers: {
                Authorization: 'Bearer ' + auth0.accessToken,
            },
            json: { email_verified: true },
            timeout: 5000,
        },
        function (err, response, body) {
            // Setting email verified isn't propagated to id_token in this
            // authentication cycle so explicitly set it to true given no errors.
            context.idToken.email_verified = !err && response.statusCode === 200;

            // Return with success at this point.
            return callback(null, user, context);
        }
    );
}
