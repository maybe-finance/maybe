/* eslint-disable */
export default {
    displayName: 'design-system',
    preset: '../../jest.preset.js',
    transform: {
        '^.+\\.[tj]sx?$': ['babel-jest', { presets: ['@nrwl/react/babel'] }],
    },
    moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx'],
    coverageDirectory: '../../coverage/libs/design-system',
    setupFilesAfterEnv: ['./jest.setup.js'],
}
