module.exports = {
  env: {
    commonjs: true,
    es6: true,
    node: true,
  },
  extends: [
    'airbnb-base',
  ],
  globals: {
    Atomics: 'readonly',
    SharedArrayBuffer: 'readonly',
  },
  parserOptions: {
    ecmaVersion: 2018,
  },
  rules:{
    'prefer-promise-reject-errors':0,
    'max-len':["error", {"code": 200,"comments":200}],
    'consistent-return':0,
    'no-restricted-syntax':0,
    'camelcase':0,
    'no-async-promise-executor':0,
  },
};
