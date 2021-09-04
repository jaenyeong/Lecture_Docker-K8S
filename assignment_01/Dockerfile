FROM nginx:alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY ./* ./

EXPOSE 80

# Add exec permission to sh
#RUN chmod +x ./docker-entrypoint.sh
#ENTRYPOINT ["./docker-entrypoint.sh"]
#CMD ["nginx", "-g", "daemon off;"]

ENTRYPOINT ["nginx", "-g", "daemon off;"]

HEALTHCHECK --interval=2s --timeout=5s --retries=5 \
CMD curl -f http://localhost/ || exit 1
