module.exports = {
    stories: [],

    // uncomment the property below if you want to apply some webpack config globally
    // webpackFinal: async (config, { configType }) => {
    //   // Make whatever fine-grained changes you need that should apply to all storybook configs
    //   // Return the altered config
    //   return config;
    // },
    addons: ['@storybook/addon-essentials'],

    framework: {
        name: '@storybook/nextjs',
        options: {},
    },

    docs: {
        autodocs: true,
    },
}
