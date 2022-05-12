FROM php:7.4.29-apache

WORKDIR /var/www/html

RUN echo "locales locales/locales_to_be_generated multiselect pt_BR.UTF-8 UTF-8" | debconf-set-selections && \
	echo "locales locales/default_environment_locale select pt_BR.UTF-8" | debconf-set-selections

RUN apt-get update && apt-get install -y \
        locales \
		locales-all \
		git \
		libcurl4-openssl-dev \
		curl \
		imagemagick \
		libicu-dev \
		libpng-dev \
		libmariadb-dev-compat \
		libmariadb-dev \
        libssl-dev \
		libonig-dev \
		libxml2-dev \
        libmemcached11 \
        openssl \
		python3 \
		librsvg2-bin \
	--no-install-recommends \
	&& apt-get purge -y --auto-remove \
	&& rm -r /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
	sed -i '/pt_BR.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

ENV LC_ALL pt_BR.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Instalacao de dependencias PHP necessarias.
RUN docker-php-ext-install sockets xml mbstring opcache intl curl gd pdo_mysql mysqli

# Instalacao do cache default.
RUN pecl channel-update pecl.php.net \
	&& pecl install apcu \
	&& docker-php-ext-enable apcu

# Configuracao do apache.
COPY config/000-default.conf /etc/apache2/sites-available/
RUN chown -R www-data:www-data /var/www/*

# Definicao do PHP.ini conforme:
# https://secure.php.net/manual/en/opcache.installation.php.
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini


#PDO - CUSTOMIZAR A SEU DISPOR
RUN docker-php-ext-install pdo_mysql
RUN git clone "https://github.com/rneto12/Cadastro-Pacientes.git" .
RUN git fetch
RUN git status

# Personalizando mensagens de erro
RUN echo "<h1 style='color:maroon'>Error 404: Not found :-(</h1>" | tee /var/www/html/custom_404.html && \
    echo "<p>A pagina nao existe. Tem certeza que o endereco esta correto?</p>" | tee -a /var/www/html/custom_404.html && \
	echo "<h1>Oops! Something went wrong...</h1>" | tee /var/www/html/custom_50x.html && \
	echo "<p>Parece um problema tecnico. Aguarde um momento ou entre em contato com a equipe de TI.</p>" | tee -a /var/www/html/custom_50x.html && \
	chown www-data:www-data -R /var/www/*

RUN sed -i "s/expose_php = On/expose_php = off/g" /usr/local/etc/php/php.ini-production && \
	cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
	sed -i "s/ServerSignature On/ServerSignature Off/g" /etc/apache2/conf-enabled/security.conf && \
	sed -i "s/ServerTokens OS/ServerTokens Prod/g" /etc/apache2/conf-enabled/security.conf


EXPOSE 80

#USER www-data

CMD [ "apache2-foreground" ]