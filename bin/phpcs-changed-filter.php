<?php
// This file is part of the Moodle Claude harness.

$jsonfile = $argv[1];
$difffile = $argv[2];
$fullfiles = array_fill_keys(array_slice($argv, 3), true);

$payload = json_decode(file_get_contents($jsonfile), true);
if (!is_array($payload) || !isset($payload['files']) || !is_array($payload['files'])) {
    fwrite(STDERR, "ERROR: Unable to parse PHPCS JSON output.\n");
    exit(2);
}

$changed = [];
$currentfile = null;
foreach (file($difffile, FILE_IGNORE_NEW_LINES) as $line) {
    if (preg_match('/^\+\+\+ b\/(.+)$/', $line, $matches)) {
        $currentfile = $matches[1];
        if (!isset($changed[$currentfile])) {
            $changed[$currentfile] = [];
        }
        continue;
    }
    if ($currentfile !== null && preg_match('/^\@\@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? \@\@/', $line, $matches)) {
        $start = (int) $matches[1];
        $count = isset($matches[2]) && $matches[2] !== '' ? (int) $matches[2] : 1;
        if ($count === 0) {
            continue;
        }
        $end = $start + $count - 1;
        $changed[$currentfile][] = [$start, $end];
    }
}

$filtered = [];
$totalerrors = 0;
$totalwarnings = 0;

foreach ($payload['files'] as $file => $info) {
    $messages = $info['messages'] ?? [];
    $relative = $file;
    if (str_starts_with($relative, getcwd() . DIRECTORY_SEPARATOR)) {
        $relative = substr($relative, strlen(getcwd()) + 1);
    }

    if (isset($fullfiles[$relative])) {
        $kept = $messages;
    } else {
        $ranges = $changed[$relative] ?? [];
        $kept = [];
        foreach ($messages as $message) {
            $line = (int) ($message['line'] ?? 0);
            foreach ($ranges as [$start, $end]) {
                if ($line >= $start && $line <= $end) {
                    $kept[] = $message;
                    break;
                }
            }
        }
    }

    if (!$kept) {
        continue;
    }

    $errors = 0;
    $warnings = 0;
    foreach ($kept as $message) {
        if (($message['type'] ?? '') === 'ERROR') {
            $errors++;
            $totalerrors++;
        } else {
            $warnings++;
            $totalwarnings++;
        }
    }

    $filtered[$relative] = [
        'errors' => $errors,
        'warnings' => $warnings,
        'messages' => $kept,
    ];
}

if (!$filtered) {
    echo "No PHPCS issues found on changed lines.\n";
    exit(0);
}

foreach ($filtered as $file => $info) {
    echo $file . PHP_EOL;
    foreach ($info['messages'] as $message) {
        $line = $message['line'] ?? '?';
        $column = $message['column'] ?? '?';
        $type = $message['type'] ?? 'INFO';
        $source = $message['source'] ?? 'unknown';
        $text = trim($message['message'] ?? '');
        echo "  Line {$line}, Col {$column} [{$type}] {$source}: {$text}" . PHP_EOL;
    }
}

echo PHP_EOL;
echo "Changed-line PHPCS summary: {$totalerrors} error(s), {$totalwarnings} warning(s)." . PHP_EOL;
exit($totalerrors > 0 || $totalwarnings > 0 ? 1 : 0);
