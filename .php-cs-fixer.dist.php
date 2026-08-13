<?php

declare(strict_types=1);

use Ergebnis\License;

$finder = (new PhpCsFixer\Finder())
    ->in([__DIR__ . '/src', __DIR__ . '/tests'])
    ->name('*.php')
    ->name('*.phtml')
    ->ignoreDotFiles(true)
    ->ignoreVCS(true);

$license = License\Type\None::text(
    License\Range::since(
        License\Year::fromString('2026'),
        new DateTimeZone('UTC')
    ),
    License\Holder::fromString('MACO Studios in colaboration with Gubee'),
    License\Url::fromString('https://github.com/maco-studios/gubee-module-gubee-integration')
);

return (new PhpCsFixer\Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PSR12' => true,
        'array_syntax' => ['syntax' => 'short'],
        'declare_strict_types' => true,
        'no_unused_imports' => true,
        'ordered_imports' => ['sort_algorithm' => 'alpha'],
        'single_quote' => true,
        'trailing_comma_in_multiline' => true,
        'no_trailing_whitespace' => true,
        'blank_line_after_namespace' => true,
        'blank_line_after_opening_tag' => true,
        'concat_space' => ['spacing' => 'one'],
        'no_empty_statement' => true,
        'no_extra_blank_lines' => true,
        'not_operator_with_successor_space' => true,
        'return_type_declaration' => ['space_before' => 'none'],
        'ternary_operator_spaces' => true,
        'unary_operator_spaces' => true,
        'header_comment' => [
            'comment_type' => 'PHPDoc',
            'header' => $license->header(),
            'location' => 'after_declare_strict',
            'separate' => 'both',
        ],
    ])
    ->setIndent('    ')
    ->setLineEnding("\n")
    ->setFinder($finder);
