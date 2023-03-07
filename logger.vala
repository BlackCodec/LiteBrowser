namespace Litebrowser {

	public class LoggerRecord {
		public LoggerRecord parent; 
		public string class_name;
		public string method_name;
		public LoggerRecord(string class_name, string method_name, LoggerRecord? parent) {
			this.class_name = class_name;
			this.method_name = method_name;
			this.parent = parent;
		}
		
		public bool has_parent() { return this.parent != null; }
	}

    public class Logger {
        
        private const string MESSAGE_FORMAT = "<%s> [%s] %s.%s(): %s";
        private bool enabled;
        private LoggerRecord current_log;
        
    	public Logger(bool enabled = true) {
    		this.enabled = enabled;
    		this.current_log = new LoggerRecord("root","main",null);
    	}
    	
    	public void entering(string class_name, string method_name) {
    		LoggerRecord source = new LoggerRecord(class_name, method_name, this.current_log);
			this.current_log = source;
    		this.trace("Entering %s.%s".printf(class_name, method_name));
    	}
    	public void exiting(string class_name, string method_name) {
    		this.trace("Exiting %s.%s".printf(class_name, method_name));
    		if (this.current_log.has_parent()) {
    			this.current_log = this.current_log.parent;
			} else {
	    		this.current_log = new LoggerRecord("root","main",null);
    		}
    	}
    	public void info(string message) {
	    	this.logp(this.current_log.class_name, this.current_log.method_name, "info", message);
    	}
    	public void warn(string message) {
	    	this.logp(this.current_log.class_name, this.current_log.method_name, "warning", message);
    	}
    	public void severe(string message) {
    		this.logp(this.current_log.class_name, this.current_log.method_name, "severe", message);
    	}
    	public void debug(string message) {
	    	this.logp(this.current_log.class_name, this.current_log.method_name, "debug", message);
    	}
    	public void trace(string message) {
    		this.logp(this.current_log.class_name, this.current_log.method_name, "trace", message);
    	}
    	
    	public void logp(string class_name, string method_name, string level, string message) {
    		if (this.enabled) {
	    		string date_now = new DateTime.now_local().to_string();
    			string message_to_print = MESSAGE_FORMAT.printf(date_now, level.up(), class_name, method_name, message);
    			print("%s\n".printf(message_to_print));
			}
    	}
    }
}