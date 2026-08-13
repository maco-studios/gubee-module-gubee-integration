[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](#license)
[![PHP Version](https://img.shields.io/badge/PHP-%3E%3D8.1-777BB4.svg)](composer.json)
[![Magento](https://img.shields.io/badge/Magento-2.4.8%2B-F26322.svg)](compose.yml)

English | [Português](README.pt-BR.md)

## Installation

This walks through adding the module to an existing Magento 2 project from scratch.

1. Add the Gubee SDK repository your Magento project needs to resolve this module's dependency (skip if already configured):

   ```bash
   composer config repositories.gubee-sdk vcs git@github.com:maco-studios/gubee-php-sdk.git
   ```

2. Require the module:

   ```bash
   composer require gubee-marketplace/module-gubee-integration
   ```

3. Enable the module and apply setup:

   ```bash
   bin/magento module:enable Gubee_Integration
   bin/magento setup:upgrade
   bin/magento cache:flush
   ```

4. Confirm it's active:

   ```bash
   bin/magento module:status Gubee_Integration
   ```

   You should see `Gubee_Integration` listed under "List of enabled modules".

## Running Tests

```bash
composer test
```

Runs the [Pest](https://pestphp.com) suite in `tests/` (`Feature/` and `Unit/`), bootstrapped by `tests/Pest.php` and `tests/TestCase.php`.

To run the full lint + static analysis + normalization check:

```bash
composer lint
```

## Uninstalling

To remove the module from a Magento 2 store:

```bash
bin/magento module:uninstall Gubee_Integration
```

## Feedback

Found a bug or have a question? [Open an issue](https://github.com/maco-studios/gubee-module-gubee-integration/issues).

## License

Proprietary — Copyright (c) 2026 MACO Studios in colaboration with Gubee. All rights reserved. See the license header in [`src/registration.php`](src/registration.php) for the canonical copyright notice; there is no separate `LICENSE.md` file since this is not an open-source release.
