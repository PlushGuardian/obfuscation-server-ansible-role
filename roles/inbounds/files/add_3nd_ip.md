⚙️ Step 1: Configure Inbound Rules

Create two inbound rules, each listening on a different port and bound to a different IP.

    Go to 3X-UI Panel → Inbounds → Add Inbound.

    Create the First Inbound Rule:

        Listen IP: Enter your server's first IP address (e.g., 192.168.1.11)

. The Listen IP field in the UI controls the listen parameter in the underlying Xray configuration

.

Port: Enter a port number (e.g., 30301)

    .

    Protocol: Select your preferred protocol, such as vmess or vless.

    Complete other settings as needed (e.g., Transport, TLS) and click Save.

Create the Second Inbound Rule following the same steps:

    Listen IP: Enter your server's second IP address (e.g., 192.168.1.12)

        .

        Port: Enter a different port number (e.g., 30401).

        Configure other settings and click Save.

After creation, the system will generate a unique tag for each inbound rule. The format is usually inbound-<IP>:<PORT>, for example, inbound-192.168.1.11:30301. Please make a note of these tags, as you will need them in the third step

.
🔄 Step 2: Configure Outbound Rules

Next, configure how the proxy's egress traffic should be handled. You need to create a corresponding freedom outbound for each IP.

    Go to 3X-UI Panel → Xray Configs → Advanced → Outbounds

.

Click Add Outbound to create the First Outbound Rule:

    Protocol: Select freedom (which means direct internet access)

.

Tag: Enter a recognizable tag, such as out-ip1.

Send Through: This is the key field. Enter your server's first IP address (e.g., 192.168.1.11)
. This parameter tells Xray to use this specific IP for all outgoing connections

        .

        Click Save.

    Click Add Outbound again to create the Second Outbound Rule:

        Protocol: freedom

        Tag: out-ip2

        Send Through: Your server's second IP address (e.g., 192.168.1.12).

        Click Save.

🗺️ Step 3: Configure Routing Rules

Now, you need to use routing rules to "bind" each inbound to its corresponding outbound. This ensures that traffic entering through a specific IP also leaves through that same IP.

    In the Xray Configs → Advanced section, switch to the Routing Rules tab

.

Click Add Rule to create the First Routing Rule:

    Type: field

    Inbound Tags: Enter the first inbound tag you noted down in Step 1 (e.g., inbound-192.168.1.11:30301)

.

Outbound Tag: Enter the first outbound tag you defined in Step 2 (e.g., out-ip1)

    .

    Click Save.

Click Add Rule again to create the Second Routing Rule:

    Type: field

    Inbound Tags: The second inbound tag (e.g., inbound-192.168.1.12:30401).

    Outbound Tag: The second outbound tag (e.g., out-ip2).

    Click Save.
