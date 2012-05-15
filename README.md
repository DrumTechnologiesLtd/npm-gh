# npm-gh

A simple [npm][#NPM] wrapper, using GitHub as a light-weight npm registry for publishing.

Invokes `npm $*`, UNLESS:
* the first argument is `publish`, AND
* the package.json contains `"registry": { "type": "git", "url": "$GIT_NPM_REGISTRY"}`,

in which case instead of performing the standard npm publish, it will publish the package to the `$GIT_NPM_REGISTRY`.

The wrapper will ignore `"private": true` in the package.json, as the whole point is to be able to publish
private packages to a potentially private GitHub repo which is used instead of an npm registry.

## Why?

I wanted:

* A private [NPM][#NPM] registry,
* which was easily accessible by GitHub teams and users,
* who already had access to my private GitHub repos,
* but did not necessarily have access to my corporate intranet / vpn.

I did not want:

* To have to maintain a private NPM registry on a public server.
* To have individual GitHub repos for each npm package
* To spend the time to modify an npm fork.

# Installation


# Use

# License

This package is made available under the [MIT][#MIT] License.

[#NPM]: http://npmjs.org/
[#MIT]: http://en.wikipedia.org/wiki/MIT_License
