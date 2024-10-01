const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');

module.exports = (env, argv) => {
    return {
        entry: './web/index.js',
        output: {
            path: path.resolve(__dirname, 'web/dist'),
            filename: 'script.[contenthash].js',
        },
        plugins: [
            new HtmlWebpackPlugin({
                template: path.resolve(__dirname, 'web/assets/template.html'),
                filename: '../index.html',
                warning: '<!-- \n\n\nDO NOT CHECK INTO VERSION CONTROL. \n\nThis file is generated! Please edit template.html instead!  -->\n\n',

                minify: {
                    collapseWhitespace: true,
                    keepClosingSlash: true,
                    removeRedundantAttributes: true,
                    removeScriptTypeAttributes: true,
                    removeStyleLinkTypeAttributes: true,
                    useShortDoctype: true,
                    minifyCSS: true,
                    minifyJS: true,
                },
            }),
            new CleanWebpackPlugin(),
        ],
        devtool: argv.mode == 'development' ? 'source-map' : false,
    }
};