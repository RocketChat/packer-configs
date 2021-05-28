# RC packer files for DO, AWS and Oracle markeplace images

This repo is a Github Action used for building and testing our cloud base images using Packer.

## Development

For development or local build, build and run the docker container, setting as environment variables:
- `INPUT_ROCKETCHAT_VERSION` - The desired version of Rocket.Chat to build
- `INPUT_DO_TOKEN` - Your DigitalOcean token
- `INPUT_AWS_KEY_ID` - Your AWS key ID
- `INPUT_AWS_SECRET_KEY` - Your AWS secret

Ex:

`docker build . -t RocketChat/packer-action:latest && docker run -it -e INPUT_ROCKETCHAT_VERSION=3.14.0 -e INPUT_DO_TOKEN=mytokenhere -e INPUT_AWS_KEY_ID=myawskeyid -e INPUT_AWS_SECRET_KEY=myawssecret RocketChat/packer-action`
