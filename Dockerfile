FROM ubuntu:18.04

WORKDIR /nginx

# software-properties-common for add-apt-repository
# libpcre3 for nginx http_rewrite_module
# zlib1g-dev for nginx http_gzip_module
RUN apt-get update -qq && apt-get install -y \
        build-essential \
        git \
        software-properties-common \
    && add-apt-repository ppa:maxmind/ppa -y && apt-get update -qq \
    && apt-get install -y libmaxminddb0 libmaxminddb-dev mmdb-bin \
    && git clone -b release-1.15.2 --single-branch --depth 1 --recursive https://github.com/nginx/nginx.git \
    && git clone -b 3.1 --recursive https://github.com/leev/ngx_http_geoip2_module.git

RUN apt-get install -y \
        cmake \
        libpcre3-dev \
        zlib1g-dev \
        liblzma-dev liblzma5 xz-utils \
        libssl-dev

RUN cd nginx \
    && ./auto/configure --add-dynamic-module=/nginx/ngx_http_geoip2_module \
        --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module   --with-http_stub_status_module --with-http_auth_request_module --with-threads --with-stream --with-stream_ssl_module --with-stream_ssl_preread_module --with-stream_realip_module --with-http_slice_module --with-mail --with-mail_ssl_module --with-compat --with-file-aio  --with-http_v2_module \
    && make && make install

RUN adduser --system --group --no-create-home --shell /bin/false nginx 

RUN apt-get update -qq && apt-get install -y wget \
    && wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz \
    #&& wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity_CSV/GeoLiteCity-latest.zip \
    #&& wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip \
    && wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz \
    && mkdir GeoLite2-Country GeoLite2-City \
    && ls -l \
    && tar xvfz GeoLite2-Country.tar.gz -C GeoLite2-Country --strip 1 \
    #&& unzip GeoLiteCity-latest.zip \
    #&& unzip GeoLite2-City-CSV.zip \
    && tar xvzf GeoLite2-City.tar.gz -C GeoLite2-City --strip 1 \
    && mkdir /usr/local/share/GeoIP \
    && mv GeoLite2-City/GeoLite2-City.mmdb /usr/local/share/GeoIP/ \
    && mv GeoLite2-Country/GeoLite2-Country.mmdb /usr/local/share/GeoIP/ \
    && ls -l

COPY nginx.conf /etc/nginx/
RUN mkdir /var/cache/nginx
RUN mkdir -p /usr/share//nginx/html && touch /usr/share/nginx/html/index.html && echo "Hi." > /usr/share/nginx/html/index.html

CMD ["nginx", "-g", "daemon off;"]
