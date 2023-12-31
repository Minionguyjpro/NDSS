# 🚀 NGROK to deSEC Tunnel Script
- This script will help you to create a tunnel to your local Minecraft server using Ngrok and deSEC.
- Creates an Ngrok TCP tunnel and sets the required DNS records on deSEC.
- Opens your local Minecraft server to the world without any hassle. 
- Port forwarding, firewall settings or any other configuration is not required, everything is handled by Ngrok and deSEC.

# 🏃 How to use
- Clone this repository
- Copy `ndss.example.sh` to `ndss.sh` and edit it with your details.
- Create a CNAME record on your deSEC DNS dashboard (Instructions in `ndss.sh` file)
- Create an SRV record on your deSEC DNS dashboard (Instructions in `ndss.sh` file)
- Run `ndss.sh` and wait
- You (and everyone in the world!) can now connect to your Minecraft server using your domain name.

# 🧦 Contributing

Feel free to use GitHub's features.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/my-feature`)
3. Commit your Changes (`git commit -m 'my awesome feature my-feature'`)
4. Push to the Branch (`git push origin feature/my-feature`)
5. Open a Pull Request

# 🔥 Show your support

Give a ⭐️ if this project helped you!

# 👏 Credits
Thanks to [barbarbar338](https://github.com/barbarbar338) for the base of this project, [ncfs](https://github.com/barbarbar338/ncfs). It's a project that allows you to do the exact same, but instead of deSEC it uses a CloudFlare domain. This project is based on it, but is for deSEC domains (which are free) instead.

# 📞 Contact

-   Mail: minionguyjpro@gmail.com
