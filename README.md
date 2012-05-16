# npm-gh

A simple [npm][#NPM] bash wrapper, to use GitHub as a light-weight npm registry for publishing.

## Why?

I wanted:

* A private [NPM][#NPM] registry,
* which was easily accessible by GitHub teams and users,
* who already had access to my private GitHub repos,
* but did not necessarily have access to my corporate intranet / vpn.

I did not want:

* To have to maintain a private NPM registry on a public / hosted server.
* To have individual GitHub repos for each npm package.
* To spend the time to modify an npm fork.

I don't care about:

* Having a web-based search-able, browse-able interface; GitHub is good enough for me.
* The unsightly git output when `npm-gh` publishes to a repo. I might fix it one day, when I care more.

# Installation

First of all, you'll need [npm][#NPM].

Then at a command-line:

    npm install -g  git://github.com/NetDevLtd/npm-gh.git#npm-gh/0.0.1

Yep, that's right, `npm-gh` uses its own repo as a GitHub-backed *public* npm registry for itself.

You can also get it from the public npm registry at http://search.npmjs.org, so this should also work:

    npm install -g npm-gh

# Use

In your package.json you need the following:

    "name": "$myPackage",
    "version": "$myVersion",
    "registry": {
      "type": "git",
      "url": "git@github.com:$GitHubAccount/$RegistryRepo.git
    }

If any of the above properties do not exist, or if you invoked `npm-gh` in any other way, `npm` is called instead.

Once your package.json is ready, you can run `npm-gh publish`, and it will publish version `$myVersion` of `$myPackage` to `$RegistryRepo` on `$GitHubAccount`, assuming you have the correct GitHub permissions to do so.

In another package which depends on `$myPackage` you should add the following to your package.json dependency list:

    "$myPackage": "git+ssh://git@github.com:$GitHubAccount/$RegistryRepo.git#$myPackage/$myVersion"

`git+ssh://git@github.com:$GitHubAccount...` is necessary for `$RegistryRepo`s which are private.

`git://github.com/$GitHubAccount..` should be sufficient for `$RegistryRepo`s which are public.

## Notes

### Differences from npm

`npm publish` allows you to specify tarballs and / or directories to publish.

`npm-gh` currently only allows you to publish your current working directory.
The next release will address that.

### Private packages

`npm-gh` ignores the `private` property of your package.json, as the whole point was to be able to publish private packages to a potentially private GitHub repo, instead of the public npm registry.

### Updating published packages
`npm-gh` will allow you to update an existing published version.

While this is bad practice for released versions, the script allows it, to keep it simple, and
also to allow for pre-release versions to change during the R&D lifecycle, without bumping version numbers in the package.json.

### Registry Maintenance

Removal and pruning of obsolete versions of packages is currently only possible by deleting the appropriate branches in the $RegistryRepo via git.

# License

This package is made available under the [MIT][#MIT] License.


[#NPM]: http://npmjs.org/
[#MIT]: http://en.wikipedia.org/wiki/MIT_License
