FROM php:8.4-cli

ARG YAKPRO_REF=2.0.17
ARG PHP_PARSER_REF=v4.9.1

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --depth=1 --branch "${YAKPRO_REF}" https://github.com/pk-fr/yakpro-po.git /opt/yakpro-po \
    && git clone --depth=1 --branch "${PHP_PARSER_REF}" https://github.com/nikic/PHP-Parser.git /opt/yakpro-po/PHP-Parser

WORKDIR /workspace

ENTRYPOINT ["php", "/opt/yakpro-po/yakpro-po.php"]
