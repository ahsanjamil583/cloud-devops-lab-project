module.exports = [
  {
    files: ["**/*.js"],

    ignores: [
      "node_modules/**",
    ],

    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "commonjs",

      globals: {
        console: "readonly",
        process: "readonly",
        require: "readonly",
        module: "readonly",
      },
    },

    rules: {
      "no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
        },
      ],

      "no-undef": "error",
      "eqeqeq": "error",
      "semi": ["error", "always"],
    },
  },
];
