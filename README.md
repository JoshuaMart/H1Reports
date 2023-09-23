# H1Reports

Simple script to retrieve Hackerone public reports.  
The following filters are applied :
  - Skip if the report is not fully disclosed
  - Skip if report status is `N/A`, `Spam`, `Duplicate` or `Informative`

## Setup

```bash
gem install bundler
bunle install
```

or 

```bash
gem install typhoeus
```

## Run
```bash
ruby sync.rb
```