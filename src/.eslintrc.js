module.exports = {
    "env": {
        "browser": true,
        "es6": true
    },
    "extends": [
        //"eslint:recommended",
        //"plugin:react/recommended",
        "airbnb",
        "airbnb/hooks",
        "eslint-config-airbnb"
    ],
    "globals": {
        "Atomics": "readonly",
        "SharedArrayBuffer": "readonly"
    },
    "parser": "babel-eslint",
    "parserOptions": {
        "ecmaFeatures": {
            "jsx": true
        },
        "ecmaVersion": 2018,
        "sourceType": "module"
    },
    "plugins": [
        //"react",
        "babel",
    ],
    "rules": {
        "babel/no-unused-expressions": [1, { allowShortCircuit: true, allowTernary: true} ],
        "babel/quotes": [1, 'single', { avoidEscape: true, allowTemplateLiterals: true,  }],
        "react/prop-types": "off",
        "react/jsx-props-no-spreading": 0,
        "react/jsx-filename-extension": 0,
        "react/no-array-index-key": 0,
        "react/destructuring-assignment": 0,
        "consistent-return": 0,
        "arrow-body-style": [1, 'as-needed'],
        "no-tabs": ["error", { allowIndentationTabs: true }],
        "max-len": ["warn"],
        "no-unused-vars": 1,
        "import/no-extraneous-dependencies": 0,
        "linebreak-style": [
            "error",
            "unix"
        ],
        "semi": [
            "error",
            "always"
        ]
    }
};
