# 📃 inara (from JOSS)

> This is a fork to generate reports at QIB
> Original repository: [inara](https://github.com/openjournals/inara)
> Original [README.md](README_OLD.md)

Prepare a report using two files:
* paper.md (Markdown with metadata in header and references as '`[@ref]`')
* paper.bib (BibTeX bibliography)

## Build

```bash
docker build --platform linux/amd64  -t corebioinforeport:latest  .
```

## Use

Input file is the relative path to paper.md (as we mount `$PWD` to `/data`):

```bash
docker run --rm -it -v "$PWD":/data -u $(id -u):$(id -g) corebioinforeport \
    -o pdf,crossref,html,preprint \
    paper/paper.md
```

will produce `paper.pdf` in the directory where `paper.md` is.