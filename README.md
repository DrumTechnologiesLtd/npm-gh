# npm-gh

A simple [npm][#NPM] bash wrapper, to use GitHub as a light-weight npm registry for publishing.

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

First of all, you'll need [npm][#NPM].

Then clone this repo, and run `npm install -g`.

# Use

In your package.json you need the following:

    "name": "$myPackage",
    "version": "$myVersion",
    "registry": {
      "type": "git",
      "url": "git@github.com:$GitHubAccount/$RegistryRepo.git
    }

You can then run `npm-gh publish`, and it will publish version `$myVersion` of `$myPackage` to `$RegistryRepo` on `$GitHubAccount`, assuming you have the correct GitHub permissions to do so.

In another package's which depends on `$myPackage` you should add the following to your package.json dependency list:

    "$myPackage": "git+ssh://git@github.com:$GitHubAccount/$RegistryRepo.git#$myPackage/$myVersion"

`git+ssh:` is necessary for `$RegistryRepo`s which are private, otherwise `git:` should be sufficient.

If the above registry properties do not exist, or if you invoked `npm-gh` in any other way, `npm` is called instead.

**Note**: `npm-gh` will allow you to update an existing published version.
While this is bad practice, the script allows it to keep it simple.
It also allows for snapshot / develop versions to change during development / testing / integration before a formal release is made.

Removal and pruning of obsolete versions of packages is currently only possible by deleting the appropriate branches in the $RegistryRepo.

# License

This package is made available under the [MIT][#MIT] License.

[#NPM]: http://npmjs.org/
[#MIT]: http://en.wikipedia.org/wiki/MIT_License
