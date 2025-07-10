# Released 2024-05-11
FROM pandoc/latex:3.2.0-alpine

# Install system dependencies and fonts in one layer
RUN apk add --no-cache \
    ttf-hack \
    ttf-opensans \
    && rm -rf /var/cache/apk/*

# Set up TeX Live repository 
RUN tlmgr option repository http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2024/tlnet-final && \
    tlmgr update --self

# Disable problematic LuaJIT engines BEFORE installing packages
# This prevents "Can't create the Lua state" errors in emulated environments
RUN fmtutil-sys --disablefmt luajittex 2>/dev/null || true && \
    fmtutil-sys --disablefmt luajithbtex 2>/dev/null || true && \
    # Also disable in the configuration file to prevent auto-regeneration
    sed -i 's/^luajittex/#luajittex/' /opt/texlive/texdir/texmf-dist/web2c/fmtutil.cnf && \
    sed -i 's/^luajithbtex/#luajithbtex/' /opt/texlive/texdir/texmf-dist/web2c/fmtutil.cnf

# Install LaTeX packages with error handling
# Split installation to handle collection-context separately
RUN tlmgr install \
    algorithmicx \
    algorithms \
    draftwatermark \
    environ \
    fontsetup \
    hyperxmp \
    latexmk \
    lineno \
    marginnote \
    newcomputermodern \
    orcidlink \
    preprint \
    seqsplit \
    tcolorbox \
    titlesec \
    trimspaces \
    xkeyval \
    xstring

# Install collection-context with specific error handling
RUN tlmgr install collection-context || \
    (echo "Warning: collection-context installation had issues, but continuing..." && \
     # Try to install just the essential ConTeXt components
     tlmgr install context --no-depends-at-all 2>/dev/null || true)

# Set font directory environment variable
ENV OSFONTDIR=/usr/share/fonts

# Copy custom fonts first (for better layer caching)
COPY ./fonts/libre-franklin $OSFONTDIR/libre-franklin

# Configure fonts and regenerate caches
# Using TERM=dumb to avoid terminal-related issues
RUN TERM=dumb luaotfload-tool --update && \
    # Make TeX directories writable for runtime font updates
    chmod -R o+w /opt/texlive/texdir/texmf-var && \
    # Update font cache for custom fonts
    fc-cache -sfv $OSFONTDIR/libre-franklin && \
    # Regenerate ConTeXt caches (avoiding LuaJIT if disabled)
    mtxrun --generate && \
    (mtxrun --script font --reload || true)

# Set up application directories and environment
ARG openjournals_path=/usr/local/share/openjournals
ENV OPENJOURNALS_PATH=$openjournals_path
ENV JOURNAL=joss

# Copy application resources
# Copying in separate layers for better caching
COPY ./resources $openjournals_path
COPY ./data $openjournals_path/data
COPY ./scripts/entrypoint.sh /usr/local/bin/inara

# Make entrypoint executable
RUN chmod +x /usr/local/bin/inara

# Set working directory for convenience
WORKDIR /data

# Input is read from `paper.md` by default, but can be overridden
# Output is written to `paper.pdf`
ENTRYPOINT ["/usr/local/bin/inara"]
CMD ["paper.md"]
