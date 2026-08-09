set -e

function header_section() {
	echo "\033[1;96m\033[43m\x1B[K\n\t\t ** $1 ** \t\t\x1B[K\n\x1B[K\033[0m"
}

function usage() {
	cat <<'EOF'
Usage: ./build.sh -v <image-version> [-l] [-p]

  -v  Docker image tag, e.g. 1.0.0-local (image: tcamt-prm/tcamt-webapp:<tag>).
  -l  Also tag the image as tcamt-prm/tcamt-webapp:latest
  -p  docker push the built tag(s) (requires docker login)

Build order: (1) mvn clean install in this repo (includes vendored hit-resource-client + tcamt-acmgt), (2) docker buildx.

No separate hit-resource-client checkout is required; see module hit-resource-client/.

See BUILD.md in this repository for details and troubleshooting.
EOF
}

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

while getopts ":v:lp" flag
do
    case "${flag}" in
        v) VERSION=${OPTARG};;
        l) AS_LATEST=y;;
        p) PUSH_DOCKERHUB=y;;
        \?)
            echo "Invalid option: -${OPTARG}" >&2
            usage
            exit 2
            ;;
    esac
done

if [ -z "$VERSION" ]; then
    usage
    exit 1
fi

if [ -z "$AS_LATEST" ]; then
    AS_LATEST=n
fi

if [ -z "$PUSH_DOCKERHUB" ]; then
    PUSH_DOCKERHUB=n
fi

header_section "Building TCAMT (hit-resource-client + tcamt modules)"
cd "$ROOT_DIR"
mvn clean install -DskipTests

header_section "Building Docker Image version: $VERSION"
docker buildx build --platform linux/amd64,linux/arm64 -t tcamt-prm/tcamt-webapp:$VERSION .

if [ "$AS_LATEST" == "y" ];then
  header_section "Tag version as latest"
  docker tag tcamt-prm/tcamt-webapp:$VERSION tcamt-prm/tcamt-webapp:latest
fi

if [ "$PUSH_DOCKERHUB" == "y" ];then
  docker push tcamt-prm/tcamt-webapp:$VERSION
  header_section "Image tcamt-prm/tcamt-webapp:$VERSION successfully pushed to registry"
  if [ "$AS_LATEST" == "y" ];then
    docker push tcamt-prm/tcamt-webapp:latest
    header_section "Image tcamt-prm/tcamt-webapp:latest successfully pushed to registry"
  fi
fi
