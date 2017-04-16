# cloudburrito [![CircleCI](https://circleci.com/gh/jacksonargo/cloudburrito.svg?style=svg)](https://circleci.com/gh/jacksonargo/cloudburrito)

A slack app to download burritos from the cloud.

### Installation:

    git clone https://github.com/jacksonargo/cloudburrito.git
    cd cloudburrito
    rvm install 2.3.3
    gem install bundler
    bundle install

### Run:

    bundle exec passenger

### Test:

    bundle exec rspec
    
### Build with docker:

    docker build . -t cloudburrito
