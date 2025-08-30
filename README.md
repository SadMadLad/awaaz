# Awaaz

Awaaz is a Ruby gem for working with audio, from decoding to analysis, making it easier to process and understand sound in your projects.

## Requirements

Awaaz can decode audio in two ways:

#### 1. Shell-based decoding  
You can install **any one** of the following:

- [`ffmpeg`](https://github.com/FFmpeg/FFmpeg) – supports most formats, including MP3.  
- [`sox`](https://github.com/chirlu/sox) – also supports most formats, including MP3.  
- [`mpg123`](https://github.com/madebr/mpg123) – **MP3 only**.

#### 2. Library-based decoding and resampling  
- [`libsndfile`](https://github.com/libsndfile/libsndfile) – reads audio files (but **cannot** read MP3 files).  
- [`libsamplerate`](https://github.com/libsndfile/libsamplerate) – resamples audio samples when using `libsndfile`.  

⚠ **Important**:  
- If you need MP3 support with the library-based method, you **must also** install one of:  
  - `ffmpeg`  
  - `sox`  
  - `mpg123`

#### Additional Requirement
- The Ruby gem [`numo-narray`](https://github.com/ruby-numo/numo-narray) is required for numerical array operations.

### Installation Examples

- **Just ffmpeg** → works for all formats (no `libsndfile` or `libsamplerate` needed).  
- **Just sox** → works for all formats (no `libsndfile` or `libsamplerate` needed).  
- **libsndfile + libsamplerate** → works for non-MP3 formats. For MP3, add `ffmpeg`, `sox`, or `mpg123`.  
- **Everything installed** → maximum flexibility.

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add awaaz
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install awaaz
```

## Usage

```ruby
# To decode the audio file
samples, sample_rate = Awaaz.load("path/to/audio_file")
```

## Documentation

[Link to Documentation](https://www.rubydoc.info/gems/awaaz)

Checkout [this demo](https://github.com/SadMadLad/awaaz-demo) to get more idea of some use cases of the gem

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [Awaaz](https://github.com/SadMadLad/awaaz). This project is intended to be a safe, welcoming space for collaboration, and contributors.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
