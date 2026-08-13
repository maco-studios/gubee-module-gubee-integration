[![License: Proprietary](https://img.shields.io/badge/License-Proprietary-red.svg)](#licen%C3%A7a)
[![PHP Version](https://img.shields.io/badge/PHP-%3E%3D8.1-777BB4.svg)](composer.json)
[![Magento](https://img.shields.io/badge/Magento-2.4.8%2B-F26322.svg)](compose.yml)

🇧🇷 Português | 🇬🇧 [English](README.md)

## Instalação

Este tutorial mostra como adicionar o módulo a um projeto Magento 2 existente, do zero.

1. Adicione o repositório do SDK da Gubee, necessário para resolver a dependência deste módulo (pule se já estiver configurado):

   ```bash
   composer config repositories.gubee-sdk vcs git@github.com:maco-studios/gubee-php-sdk.git
   ```

2. Requisite o módulo:

   ```bash
   composer require gubee-marketplace/module-gubee-integration
   ```

3. Habilite o módulo e aplique o setup:

   ```bash
   bin/magento module:enable Gubee_Integration
   bin/magento setup:upgrade
   bin/magento cache:flush
   ```

4. Confirme que está ativo:

   ```bash
   bin/magento module:status Gubee_Integration
   ```

   Você deve ver `Gubee_Integration` listado em "List of enabled modules".

## Rodando os Testes

```bash
composer test
```

Roda a suíte [Pest](https://pestphp.com) em `tests/` (`Feature/` e `Unit/`), inicializada por `tests/Pest.php` e `tests/TestCase.php`.

Para rodar lint + análise estática + verificação de normalização completos:

```bash
composer lint
```

## Desinstalando

Para remover o módulo de uma loja Magento 2:

```bash
bin/magento module:uninstall Gubee_Integration
```

## Feedback

Encontrou um bug ou tem alguma dúvida? [Abra uma issue](https://github.com/maco-studios/gubee-module-gubee-integration/issues).

## Licença

Proprietária — Copyright (c) 2026 MACO Studios em colaboração com a Gubee. Todos os direitos reservados. Veja o cabeçalho de licença em [`src/registration.php`](src/registration.php) para o aviso de copyright canônico; não há um arquivo `LICENSE.md` separado, pois este não é um lançamento open-source.
