use local_ip_address::list_afinet_netifas;
use std::{
    fs::{read_to_string, write},
    process::Command,
    thread::sleep,
    time::Duration,
};

const CONF_PATH: &str = "/etc/remarkable.conf";
const FALSE_STR: &str = "WebInterfaceEnabled=false";
const TRUE_STR: &str = "WebInterfaceEnabled=true";

fn edit_conf() {
    let data = read_to_string(CONF_PATH).expect(&format!("Unable to read {}", CONF_PATH));
    if data.contains(FALSE_STR) {
        let data_fixed = data.replace(FALSE_STR, TRUE_STR);
        write(CONF_PATH, data_fixed).expect(&format!("Unable to write {}", CONF_PATH));
    }
}

fn spoof_ip() {
    if usb0up() {
        return;
    }
    let out = Command::new("/sbin/ip")
        .args(["addr", "add", "10.11.99.1/32", "dev", "usb0"])
        .output();
    match out {
        Ok(_) => {}
        Err(e) => println!("Error Setting usb0 IP: {e}")
    }
}

fn usb0up() -> bool {
    let network_interfaces_op = list_afinet_netifas();
    let network_interfaces = match network_interfaces_op {
        Ok(netint) => netint,
        Err(e) => {
            println!("Error Checking Interfaces: {e}");
            return false
        }
    };
    for (name, ip) in network_interfaces {
        if name == "usb0" && ip.is_ipv4() {
            return true
        }
    }
    return false
}

#[allow(while_true)]
fn main() {
    edit_conf();

    while true {
        spoof_ip();
        sleep(Duration::from_secs(5));
    }
}
