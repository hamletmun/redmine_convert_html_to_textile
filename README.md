# Redmine converter from HTML to Textile

This is rake task for [Redmine](http://www.redmine.org/) that uses [pandoc](http://pandoc.org/) to convert database content from Textile to Markdown formatting. The conversion is tweaked to adapt to Redmine's special features.

### Known limitations

Because Redmine's textile is different than pandoc's textile, and because of
some limitation in pandoc, the result will not be perfect, but it should be good
enough to get you started. Here are some known limitations:

## Usage

1. Backup your database
2. [Install pandoc](http://pandoc.org/installing.html)
3. Install the task:

    ```sh
    cd $REDMINE_ROOT_DIRECTORY
    wget -P lib/tasks/ https://github.com/hamletmun/redmine_convert_html_to_textile/raw/master/convert_html_to_textile.rake
    ```

4. Run the task:

    ```sh
    bundle exec rake convert_html_to_textile RAILS_ENV=production
    ```

