using Json;

namespace Litebrowser {

    public class Configs {

        private Logger logger;
        public List<string> history = new List<string>();
        public Configs(Logger logger) { 
            this.logger = logger; 
        }

        public string config_file { get; set; default = "~/.config/litebrowser/options.json"; }	
        public string download_path { get; set; default = "~/Scaricati/"; }	
        public string title { get; set; default = "LiteBrowser"; } 
        public string resolution { get; set; default = "800x600"; } 
        public string home { get; set; default = "https://www.icapito.it"; }
        public string search { get; set; default = "https://www.google.it/search?q=${text}"; }
        public string cookies_file { get; set; default = "~/.config/litebrowser/cookies.txt"; }
        public string cookies_policy { get; set; default = "never"; }
        public HashTable<string, string> bookmarks { get; set; default = new HashTable<string,string>(str_hash, str_equal); }
        public bool javascript { get; set; default = true; }
        public bool cache { get; set; default = true; }
        public bool save_history { get; set; default = true; }
        
        public bool parse_config() {
            this.logger.entering("Configs","parse_config");
            string file_name = this.config_file.replace("~",Environment.get_home_dir())
                        .replace("${HOME}",Environment.get_home_dir());
            File file = File.new_for_path (file_name);
            // Check if a particular file exists:
            if (!file.query_exists ()) { return false; }
            try {
                Parser json_parser = new Parser();
                json_parser.load_from_file(file_name);
                Json.Node node_root = json_parser.get_root();
                Json.Object root = node_root.get_object();
                foreach (unowned string name in root.get_members ()) {
                    this.logger.debug("Analize: " + name);
                    switch (name) {
                        case "resolution": 
                            this.resolution = root.get_string_member(name);
                            break;
                        case "cache":
                            this.cache = root.get_boolean_member(name);
                            break;
                        case "javascript":
                            this.javascript = root.get_boolean_member(name);
                            break;
                        case "home": 
                            this.home = root.get_string_member(name);
                            break;
                        case "search": 
                            this.search = root.get_string_member(name);
                            break;
                        case "cookies": 
                            Json.Object cookies_obj = (Json.Object) root.get_object_member(name);
                            if (cookies_obj.has_member("file")) {
                                this.logger.debug("Get member file ...");
                                this.cookies_file = cookies_obj.get_string_member("file");
                            }
                            if (cookies_obj.has_member("policy")) this.cookies_policy = cookies_obj.get_string_member("policy");
                            break;
                        case "save_history": 
                            this.save_history = root.get_boolean_member(name);
                            break;
                        case "history": 
                            Json.Array temp = root.get_array_member(name);
                            this.history.foreach((entry) => { this.history.remove(entry); });
                            foreach (unowned Json.Node item in temp.get_elements ()) {
                                this.history.append(item.get_string());
                            }
                            break;
                        case "bookmarks": 
                            HashTable<string,string> tmap = new HashTable<string,string>(str_hash, str_equal);
                            Json.Array temp = root.get_array_member(name);
                            foreach (unowned Json.Node array_item in temp.get_elements ()) {
                                // for each element if have a jsonObject with name and url key
                                Json.Object item = array_item.get_object();
                                tmap.insert(item.get_string_member("name"), item.get_string_member("url"));
                            }
                            this.bookmarks = tmap;
                            break;
                        default:
                            this.logger.warn("Unmanaged config key: %s".printf(name));
                            break;
                    }
                }
                return true;
            } catch (Error e) {
                this.logger.severe("Error parsing config file: %s".printf(e.message));
                return false;
            } finally {
                this.logger.exiting("Configs", "parse_config");
            }
        }
        
        public string to_string(string? filename, bool web = false) {
            Json.Builder builder = new Json.Builder ();
            builder.begin_object();
            builder.set_member_name("resolution");
            builder.add_string_value(this.resolution);
            builder.set_member_name("home");
            builder.add_string_value(this.home);
            builder.set_member_name("search");
            builder.add_string_value(this.search);
            builder.set_member_name("cookies");
            builder.begin_object();
            builder.set_member_name("file");
            builder.add_string_value(this.cookies_file);
            builder.set_member_name("policy");
            builder.add_string_value(this.cookies_policy);
            builder.end_object();
            builder.set_member_name("cache");
            builder.add_boolean_value(this.cache);
            builder.set_member_name("javascript");
            builder.add_boolean_value(this.javascript);
            builder.set_member_name("save_history");
            builder.add_boolean_value(this.save_history);
            if (!web) {
                builder.set_member_name("history");
                builder.begin_array();
                this.history.foreach((entry) => { builder.add_string_value(entry); });
                builder.end_array();
                builder.set_member_name("bookmarks");
                builder.begin_array();
                this.bookmarks.foreach((name,url) => {
                    Json.Builder sbuilder = new Json.Builder (); 
                    sbuilder.begin_object();
                    sbuilder.set_member_name("name");
                    sbuilder.add_string_value(name);
                    sbuilder.set_member_name("url");
                    sbuilder.add_string_value(url);
                    sbuilder.end_object();
                    Json.Node obj = sbuilder.get_root ();
                    builder.add_value(obj);
                });
                builder.end_array();
            }
            builder.end_object ();
            Json.Generator generator = new Json.Generator ();
            generator.set_pretty(true);
            Json.Node root = builder.get_root ();
            generator.set_root (root);
            if (filename != null) {
                generator.to_file(filename);
            }
            return generator.to_data(null);
        }

        public void save() {
            this.logger.entering("Configs","save");
            try {
                string file_path=this.config_file.replace("~",Environment.get_home_dir ()).replace("${HOME}",Environment.get_home_dir ());
                this.logger.debug("File path: " + file_path);
                this.to_string(file_path);
                /*
                File file = File.parse_name(file_path);
                this.logger.debug("Config file: " + file.get_uri());
                // Test for the existence of file
                FileIOStream stream = null;
                if (!file.query_exists ()) {
                    // create directory
                    if (!file.get_parent().query_exists()) {
                        this.logger.debug("File does not exists, create directory ...");
                        file.get_parent().make_directory_with_parents();
                    }
                    this.logger.debug("Create a new file ...");
                    // Create a new file with this name
                    stream = file.create_readwrite(FileCreateFlags.REPLACE_DESTINATION);
                } else {
                    this.logger.debug("File exists, replace ...");
                    stream = file.open_readwrite();
                }
                this.logger.debug("Configuration: \n" + this.to_string());
                stream.output_stream.write(this.to_string().data);
                if (!file.query_exists())
                    this.logger.severe("Unable to create config file %s".printf(this.config_file));
                    */
            } catch (Error e) {
                this.logger.severe("Error during save config file: %s".printf(e.message));
            } finally {
                this.logger.exiting("Configs","save");
            }
        }
    }
}