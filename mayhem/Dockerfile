# syntax=docker/dockerfile:1.7
# Commit image for shaka-packager, built on the org C/C++ base. Upstream's third-party sources are git
# submodules, absent from a non-recursive checkout, so they are fetched here once by pinned commit and
# build.sh (air-gapped, re-runnable) copies them into place (SPEC 6.2 item 19).
FROM ghcr.io/savantenvs/base:20261023

ARG COMMIT
ARG REPO_URL
ARG SOURCE_DATE_EPOCH
ARG SANITIZER_FLAGS
ARG COVERAGE_FLAGS=
ARG MAYHEM_JOBS=

# One line per upstream submodule: <dir under packager/third_party> <github repo> <commit its gitlink names>.
# Each lands read-only and world-readable in /opt/toolchains/deps/<name>-<sha12>/src; build.sh verifies
# the pins against the gitlinks of the checked-out tree.
USER root
RUN <<'EOF'
set -eux
while read -r name repo sha; do
  d=/opt/toolchains/deps/$name-$(echo "$sha" | cut -c1-12); mkdir -p "$d/src"; cd "$d/src"
  git init -q .; git remote add origin "https://github.com/$repo"
  git fetch -q --depth 1 origin "$sha"; git checkout -q FETCH_HEAD
  git submodule update -q --init --recursive --depth 1 || true
  echo "$sha" > "$d/REV"
  find "$d/src" -name .git -prune -exec rm -rf {} +
done <<'DEPS'
abseil-cpp abseil/abseil-cpp 255c84dadd029fd8ad25c5efb5933e47beaa00c7
c-ares c-ares/c-ares d3a507e920e7af18a5efb7f9f1d8044ed4750013
curl curl/curl 8c908d2d0a6d32abdedda2c52e90bd56ec76c24d
googletest google/googletest 15460959cbbfa20e66ef0b5ab497367e47fc0a04
json nlohmann/json 55f93686c01528224f448c19128836e7df245f72
libpng glennrp/libpng 2b978915d82377df13fcbb1fb56660195ded868a
libwebm webmproject/libwebm f2a982d748b80586ae53b89a2e6ebbc305848b8c
libxml2 GNOME/libxml2 3d840e17858de03a09fba8b202e3a89267d5795a
mbedtls Mbed-TLS/mbedtls e185d7fd85499c8ce5ca2a54f5cf8fe7dbe3f8df
mimalloc microsoft/mimalloc 4e50d6714d471b72b2285e25a3df6c92db944593
mongoose cesanta/mongoose 5c8e05a4fc34c5309ceea887a7e60b895b2100d7
protobuf protocolbuffers/protobuf b6f9284da830b69be787732ffdaa35049d20a088
zlib madler/zlib 5c42a230b7b468dff011f444161c0145b5efae59
DEPS
chmod -R a+rX /opt/toolchains/deps
EOF
USER mayhem

WORKDIR /mayhem
COPY --chown=2000:2000 . /mayhem

# Compile-cache pre-fill (SPEC 6.2 item 18); a plain build on older bases.
RUN if [ -x /opt/mayhem/ccache/prefill ]; then /opt/mayhem/ccache/prefill bash mayhem/build.sh; \
    else bash mayhem/build.sh; fi

RUN if [ -f mayhem/test.sh ]; then bash mayhem/test.sh; else echo "no mayhem/test.sh"; fi

LABEL org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.revision="${COMMIT}" \
      rlenv.tier="commit" \
      rlenv.source_date_epoch="${SOURCE_DATE_EPOCH}" \
      rlenv.user="mayhem"

USER mayhem
WORKDIR /mayhem
