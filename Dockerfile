ARG WODBY_BASE_IMAGE
FROM ${WODBY_BASE_IMAGE}

ARG COPY_FROM
COPY --chown=node:node ${COPY_FROM} /usr/src/app

# Uploaded media goes to the persistent files directory: the service mounts
# its uploads volume at $FILES_DIR (/mnt/files), outside the application code.
RUN NODE_ENV=production npm run build \
    && rm -rf public/uploads \
    && ln -s "$FILES_DIR" public/uploads

CMD ["npm", "run", "start"]
