%readme

* All files with `test_*.rb` are run with `rake test` at the top directory.
  * Here, basically files to modify the existing Ruby default classes are not require-d.
* All files with `*_test.rb` are run with `rake test all_required=true` or `make test2` at the top directory.
  * You can view with `rake -T`
  * In `*_test.rb`, all files to modify the existing Ruby default classes are required.
  
With `make test`, both files (for unit-testing) are run, providing the first one succeeds.
