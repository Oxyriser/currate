FROM node:14.4

RUN wget -O - 'https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz' \
    | gunzip -c >/usr/local/bin/elm
RUN chmod +x /usr/local/bin/elm
RUN npm install --global uglify-js

WORKDIR /app
COPY . /app
RUN elm make src/Main.elm --optimize --output=elm.js && uglifyjs elm.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters=true,keep_fargs=false,unsafe_comps=true,unsafe=true,passes=2' | uglifyjs --mangle --output elm.min.js

FROM nginx:alpine
COPY --from=0 /app /usr/share/nginx/html
