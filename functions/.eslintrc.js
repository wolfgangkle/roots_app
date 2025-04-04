module.exports = {
  root: true,
  env: {
    es2020: true, // updated from es6 for modern features
    node: true,
  },
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json"],
    sourceType: "module",
    ecmaVersion: 2020, // modern parsing
  },
  plugins: ["@typescript-eslint", "import"],
  extends: [
    "eslint:recommended",
    "plugin:import/errors",
    "plugin:import/warnings",
    "plugin:import/typescript",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
    "google"
  ],
  rules: {
    "quotes": ["error", "double"],
    "import/no-unresolved": "off", // disable false positives with .js in ESM
    "indent": ["error", 2],
    "require-jsdoc": "off", // optional: Google styleguide enforces this
    "@typescript-eslint/no-unused-vars": ["warn"],
    "@typescript-eslint/no-floating-promises": ["error"],
  },
  ignorePatterns: [
    "/lib/**/*",
    "/generated/**/*"
  ],
};
