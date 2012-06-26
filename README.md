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
* To spend the time to modify an npm fork to do what I want.

I don't care about:

* Having a web-based search-able, browse-able interface; GitHub is good enough for me.
* The unsightly progress & output from `npm-gh`. I might fix it one day, when I care more.

# Release history

* Current release: **0.0.4**

## New in 0.0.4

* Exposed getJsonValue as a command-line executable. Use: getJsonValue <jsonFile> <key>.

## New in 0.0.3

* Fixed bug where when installed locally, npm-gh would not correctly resolve the symlink to itself in node_modules
* Removed JSON.sh dependency with a node.js-based JSON parser.

## New in 0.0.2

* Added support for command-line specified package directories

## Installation
First of all, you'll need [npm][#NPM].

Then at a command-line:

    npm install -g  git://github.com/NetDevLtd/npm-gh.git#npm-gh/0.0.4

Yep, that's right, `npm-gh` uses its own repo as a GitHub-backed *public* npm registry for itself.

You can also get it from the public npm registry at http://search.npmjs.org, so this should also work:

    npm install -g npm-gh

# Use
In your package.json you need the following:

    "name": "$myPackage",
    "version": "$myVersion",
    "registry": {
      "type": "git",
      "url": "git@github.com:$GitHubAccount/$RegistryRepo.git"
    }

If any of the above properties do not exist, or if you invoked `npm-gh` in any other way, `npm` is called instead.

## Working directory
Once your package.json is ready, you can run `npm-gh publish`, and it will publish version `$myVersion` of `$myPackage` to `$RegistryRepo` on `$GitHubAccount`, assuming you have the correct GitHub permissions to do so.

## Specified directories
You can optionally specify one or more directories on the command line:

    npm-gh publish [path1] [path2] ...

It will check to see if the path is a directory, if it contains a package.json and if the package.json contains the required additional properties for `npm-gh`; if any of these fail, it skips that path and moves on.

## Specifying the dependency in other packages
In another package which depends on `$myPackage` you should add the following to your package.json dependency list:

    "$myPackage": "git+ssh://git@github.com:$GitHubAccount/$RegistryRepo.git#$myPackage/$myVersion"

`git+ssh://git@github.com:$GitHubAccount...` is necessary for `$RegistryRepo`s which are private.

`git://github.com/$GitHubAccount..` should be sufficient for `$RegistryRepo`s which are public.


# Notes
## Differences from npm

`npm publish` allows you to specify tarballs and / or directories to publish.

`npm-gh` currently only allows you to publish your current working directory and / or directories.
Tarballs are not supported in 0.0.3, and are unlikely to be any-time soon, unless someone specifically asks for it.

## Private packages
`npm-gh` ignores the `private` property of your package.json, as the whole point was to be able to publish private packages to a potentially private GitHub repo, instead of the public npm registry.

## Updating published packages
`npm-gh` will allow you to update an existing published version.

While this is bad practice for released versions, the script allows it, to keep it simple,
and also to allow for pre-release versions to change during the R&D lifecycle, without bumping version numbers in the package.json.

## Registry Maintenance
Removal and pruning of obsolete versions of packages is currently only possible by deleting the appropriate branches in the `$RegistryRepo` via git.

# License
This package is made available under the [MIT][#MIT] License.

[#NPM]: http://npmjs.org/
[#MIT]: http://en.wikipedia.org/wiki/MIT_License
