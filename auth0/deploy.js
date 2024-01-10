const { config, deploy, input_file } = require('./config')

deploy({
    config: {
        ...config,

        // The deploy client only works with the DEFAULT Auth0 domain, NOT with custom domains
        AUTH0_DOMAIN: config.AUTH0_KEYWORD_REPLACE_MAPPINGS.AUTH0_DOMAIN,
    },
    input_file,
})
    .then(() =>
        console.log(`Deployed ${config.AUTH0_KEYWORD_REPLACE_MAPPINGS.AUTH0_DOMAIN} successfully!`)
    )
    .catch((err) => console.log(`Deploy failed: ${err}`))
