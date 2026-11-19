FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/aluno \
    LANG=C.UTF-8 \
    TERM=xterm-256color

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        bash \
        coreutils \
        curl \
        file \
        findutils \
        gawk \
        grep \
        iproute2 \
        man-db \
        manpages \
        nano \
        passwd \
        procps \
        python3 \
        sed \
        tree \
        util-linux \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1000 alunos \
    && groupadd --gid 2000 auditores \
    && useradd --uid 1000 --gid alunos --groups auditores --create-home --shell /bin/bash aluno \
    && mkdir -p /opt/lab/evidencias /opt/lab/www /home/aluno/entrega

COPY evidencias/ /opt/lab/evidencias/
COPY www/index.html /opt/lab/www/index.html
COPY templates/relatorio-modelo.md /opt/lab/relatorio-modelo.md
COPY --chown=1000:1000 templates/relatorio-modelo.md /home/aluno/entrega/relatorio.md

RUN chown -R root:root /opt/lab \
    && find /opt/lab -type d -exec chmod 0555 {} + \
    && find /opt/lab -type f -exec chmod 0444 {} + \
    && chown root:auditores /opt/lab/evidencias/app.conf \
    && chmod 0640 /opt/lab/evidencias/app.conf \
    && chown root:auditores /opt/lab/evidencias/config-compartilhado.conf \
    && chmod 0664 /opt/lab/evidencias/config-compartilhado.conf \
    && chmod 0600 /opt/lab/evidencias/restrito-demo.txt \
    && chown -R aluno:alunos /home/aluno \
    && chmod 0750 /home/aluno \
    && chmod 0700 /home/aluno/entrega

WORKDIR /home/aluno
USER aluno

CMD ["python3", "-u", "-m", "http.server", "8080", "--bind", "0.0.0.0", "--directory", "/opt/lab/www"]
