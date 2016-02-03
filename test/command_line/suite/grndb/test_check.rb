class TestGrnDBCheck < GroongaTestCase
  def setup
  end

  def test_locked_database
    groonga("lock_acquire")
    error = assert_raise(CommandRunner::Error) do
      grndb("check")
    end
    assert_equal(<<-MESSAGE, error.error_output)
Database is locked. It may be broken. Re-create the database.
    MESSAGE
  end

  def test_nonexistent_table
    groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
    _id, _name, path, *_ = JSON.parse(groonga("table_list").output)[1][1]
    FileUtils.rm(path)
    error = assert_raise(CommandRunner::Error) do
      grndb("check")
    end
    assert_equal(<<-MESSAGE, error.error_output)
[Users] Can't open object. It's broken. Re-create the object or the database.
    MESSAGE
  end

  def test_locked_table
    groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
    groonga("lock_acquire", "Users")
    error = assert_raise(CommandRunner::Error) do
      grndb("check")
    end
    assert_equal(<<-MESSAGE, error.error_output)
[Users] Table is locked. It may be broken. (1) Truncate the table (truncate Users) or clear lock of the table (lock_clear Users) and (2) load data again.
    MESSAGE
  end

  def test_locked_data_column
    groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
    groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")
    groonga("lock_acquire", "Users.age")
    error = assert_raise(CommandRunner::Error) do
      grndb("check")
    end
    assert_equal(<<-MESSAGE, error.error_output)
[Users.age] Data column is locked. It may be broken. (1) Truncate the column (truncate Users.age) or clear lock of the column (lock_clear Users.age) and (2) load data again.
    MESSAGE
  end

  def test_locked_index_column
    groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
    groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")

    groonga("table_create", "Ages", "TABLE_PAT_KEY", "UInt8")
    groonga("column_create", "Ages", "users_age", "COLUMN_INDEX", "Users", "age")

    groonga("lock_acquire", "Ages.users_age")

    error = assert_raise(CommandRunner::Error) do
      grndb("check")
    end
    assert_equal(<<-MESSAGE, error.error_output)
[Ages.users_age] Index column is locked. It may be broken. Re-create index by '#{grndb_path} recover #{@database_path}'.
    MESSAGE
  end

  sub_test_case "--target" do
    def test_nonexistent_table
      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      _id, _name, path, *_ = JSON.parse(groonga("table_list").output)[1][1]
      FileUtils.rm(path)
      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Users")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Users] Can't open object. It's broken. Re-create the object or the database.
      MESSAGE
    end

    def test_locked_table
      groonga("table_create", "Bookmarks", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Bookmarks", "title",
              "COLUMN_SCALAR", "ShortText")

      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")

      groonga("lock_acquire", "Bookmarks")
      groonga("lock_acquire", "Bookmarks.title")
      groonga("lock_acquire", "Users")
      groonga("lock_acquire", "Users.age")

      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Users")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Users] Table is locked. It may be broken. (1) Truncate the table (truncate Users) or clear lock of the table (lock_clear Users) and (2) load data again.
[Users.age] Data column is locked. It may be broken. (1) Truncate the column (truncate Users.age) or clear lock of the column (lock_clear Users.age) and (2) load data again.
      MESSAGE
    end

    def test_locked_data_column
      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")

      groonga("lock_acquire", "Users")
      groonga("lock_acquire", "Users.age")

      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Users.age")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Users.age] Data column is locked. It may be broken. (1) Truncate the column (truncate Users.age) or clear lock of the column (lock_clear Users.age) and (2) load data again.
      MESSAGE
    end

    def test_nonexistent_referenced_table
      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")

      groonga("table_create", "Bookmarks", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Bookmarks", "user", "COLUMN_SCALAR", "Users")

      JSON.parse(groonga("table_list").output)[1].each do |table|
        _id, name, path, *_ = table
        FileUtils.rm(path) if name == "Users"
      end
      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Bookmarks")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Users] Can't open object. It's broken. Re-create the object or the database.
      MESSAGE
    end

    def test_referenced_table_by_table
      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")

      groonga("table_create", "Admins", "TABLE_HASH_KEY", "Users")

      groonga("lock_acquire", "Users")
      groonga("lock_acquire", "Users.age")
      groonga("lock_acquire", "Admins")

      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Admins")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Admins] Table is locked. It may be broken. (1) Truncate the table (truncate Admins) or clear lock of the table (lock_clear Admins) and (2) load data again.
[Users] Table is locked. It may be broken. (1) Truncate the table (truncate Users) or clear lock of the table (lock_clear Users) and (2) load data again.
[Users.age] Data column is locked. It may be broken. (1) Truncate the column (truncate Users.age) or clear lock of the column (lock_clear Users.age) and (2) load data again.
      MESSAGE
    end

    def test_referenced_table_by_column
      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")

      groonga("table_create", "Bookmarks", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Bookmarks", "user", "COLUMN_SCALAR", "Users")

      groonga("lock_acquire", "Users")
      groonga("lock_acquire", "Users.age")
      groonga("lock_acquire", "Bookmarks")
      groonga("lock_acquire", "Bookmarks.user")

      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Bookmarks.user")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Bookmarks.user] Data column is locked. It may be broken. (1) Truncate the column (truncate Bookmarks.user) or clear lock of the column (lock_clear Bookmarks.user) and (2) load data again.
[Users] Table is locked. It may be broken. (1) Truncate the table (truncate Users) or clear lock of the table (lock_clear Users) and (2) load data again.
[Users.age] Data column is locked. It may be broken. (1) Truncate the column (truncate Users.age) or clear lock of the column (lock_clear Users.age) and (2) load data again.
      MESSAGE
    end

    def test_locked_index_column
      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")
      groonga("column_create", "Users", "name", "COLUMN_SCALAR", "ShortText")

      groonga("table_create", "Ages", "TABLE_PAT_KEY", "UInt8")
      groonga("column_create", "Ages", "users_age", "COLUMN_INDEX",
              "Users", "age")

      groonga("lock_acquire", "Users")
      groonga("lock_acquire", "Users.age")
      groonga("lock_acquire", "Users.name")
      groonga("lock_acquire", "Ages")
      groonga("lock_acquire", "Ages.users_age")

      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Ages")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Ages] Table is locked. It may be broken. (1) Truncate the table (truncate Ages) or clear lock of the table (lock_clear Ages) and (2) load data again.
[Ages.users_age] Index column is locked. It may be broken. Re-create index by '#{grndb_path} recover #{@database_path}'.
[Users] Table is locked. It may be broken. (1) Truncate the table (truncate Users) or clear lock of the table (lock_clear Users) and (2) load data again.
[Users.age] Data column is locked. It may be broken. (1) Truncate the column (truncate Users.age) or clear lock of the column (lock_clear Users.age) and (2) load data again.
      MESSAGE
    end

    def test_indexed_table
      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")
      groonga("column_create", "Users", "name", "COLUMN_SCALAR", "ShortText")

      groonga("table_create", "Names", "TABLE_PAT_KEY", "ShortText")
      groonga("column_create", "Names", "users_names",
              "COLUMN_INDEX|WITH_SECTION", "Users", "_key,name")

      groonga("lock_acquire", "Users")
      groonga("lock_acquire", "Users.age")
      groonga("lock_acquire", "Users.name")
      groonga("lock_acquire", "Names")
      groonga("lock_acquire", "Names.users_names")

      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Names")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Names] Table is locked. It may be broken. (1) Truncate the table (truncate Names) or clear lock of the table (lock_clear Names) and (2) load data again.
[Names.users_names] Index column is locked. It may be broken. Re-create index by '#{grndb_path} recover #{@database_path}'.
[Users] Table is locked. It may be broken. (1) Truncate the table (truncate Users) or clear lock of the table (lock_clear Users) and (2) load data again.
[Users.name] Data column is locked. It may be broken. (1) Truncate the column (truncate Users.name) or clear lock of the column (lock_clear Users.name) and (2) load data again.
      MESSAGE
    end

    def test_indexed_data_column
      groonga("table_create", "Users", "TABLE_HASH_KEY", "ShortText")
      groonga("column_create", "Users", "age", "COLUMN_SCALAR", "UInt8")
      groonga("column_create", "Users", "name", "COLUMN_SCALAR", "ShortText")

      groonga("table_create", "Names", "TABLE_PAT_KEY", "ShortText")
      groonga("column_create", "Names", "users_name",
              "COLUMN_INDEX", "Users", "name")

      groonga("table_create", "NormalizedNames", "TABLE_PAT_KEY", "ShortText",
              "--normalizer", "NormalizerAuto")
      groonga("column_create", "NormalizedNames", "users_name",
              "COLUMN_INDEX", "Users", "name")

      groonga("lock_acquire", "Users")
      groonga("lock_acquire", "Users.age")
      groonga("lock_acquire", "Users.name")
      groonga("lock_acquire", "Names")
      groonga("lock_acquire", "Names.users_name")
      groonga("lock_acquire", "NormalizedNames")
      groonga("lock_acquire", "NormalizedNames.users_name")

      error = assert_raise(CommandRunner::Error) do
        grndb("check", "--target", "Users.name")
      end
      assert_equal(<<-MESSAGE, error.error_output)
[Users.name] Data column is locked. It may be broken. (1) Truncate the column (truncate Users.name) or clear lock of the column (lock_clear Users.name) and (2) load data again.
[NormalizedNames.users_name] Index column is locked. It may be broken. Re-create index by '#{grndb_path} recover #{@database_path}'.
[Names.users_name] Index column is locked. It may be broken. Re-create index by '#{grndb_path} recover #{@database_path}'.
[NormalizedNames] Table is locked. It may be broken. (1) Truncate the table (truncate NormalizedNames) or clear lock of the table (lock_clear NormalizedNames) and (2) load data again.
[Names] Table is locked. It may be broken. (1) Truncate the table (truncate Names) or clear lock of the table (lock_clear Names) and (2) load data again.
      MESSAGE
    end
  end
end
