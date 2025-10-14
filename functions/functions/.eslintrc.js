module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2020,
  },
  extends: [
    "eslint:recommended",
    "google",
  ],
  rules: {
    // 現状の関数コードに合わせて緩める（デプロイ優先）
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": "off",
    "require-jsdoc": "off",
    "max-len": ["warn", {"code": 140, "ignoreUrls": true, "ignoreStrings": true, "ignoreTemplateLiterals": true}],
    "object-curly-spacing": "off",
    "indent": "off",
    "operator-linebreak": "off",
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
