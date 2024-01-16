module.exports = {
    stories: [],
    addons: ['@storybook/addon-essentials'],
    core: {
        builder: '@storybook/builder-vite',
    },
    async viteFinal(config, { configType }) {
        // apply any global vite configs that might have been specified in .storybook/main.js
        // if (rootMain.viteFinal) {
        //     config = await rootMain.viteFinal(config, { configType })
        // }

        // add your own vite tweaks if needed

        return config
    },
}
