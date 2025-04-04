# gt-tilebuild-docker



```bash
docker build -t gt-tilebuild .
docker run --rm -v $(pwd)/data:/data gt-tilebuild
```

```
docker run --rm \
  -v $(pwd)/data:/data \
  -v $(pwd)/run.sh:/usr/local/bin/run-tilegen.sh \
  gt-tilebuild
```