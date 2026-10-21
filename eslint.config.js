module.exports = [
  // The lifecycle suites' scratch folders: a run that dies partway leaves them behind.
  { ignores: ["tests/sandbox/", "tests/sandbox-win/"] },
  {
    files: ["cli/**/*.js"],
    languageOptions: {
      sourceType: "commonjs",
      ecmaVersion: 2022,
    },
    rules: {},
  },
];
