// 定义上游服务器域名
const upstream = 'example.com';
// 定义移动设备上游服务器域名
const upstream_mobile = 'example.com';
// 定义阻止访问的区域代码
const blocked_region = ['KP', 'SY', 'PK', 'CU'];
// 定义阻止访问的IP地址
const blocked_ip_address = ['0.0.0.0', '127.0.0.1'];
// 是否使用HTTPS协议
const https = true;
// 定义替换字典，用于替换响应内容中的特定字符串
const replace_dict = {'$upstream': '$custom_domain', '//example.com': ''};

// 添加事件监听器，监听fetch事件
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

// 处理请求的主函数
async function handleRequest(request) {
  // 获取请求头中的区域信息，并转换为大写
  const region = request.headers.get('cf-ipcountry') ? request.headers.get('cf-ipcountry').toUpperCase() : '';
  // 获取请求头中的IP地址
  const ip_address = request.headers.get('cf-connecting-ip');
  // 获取请求头中的用户代理字符串
  const user_agent = request.headers.get('user-agent');

  // 根据区域代码阻止访问
  if (blocked_region.includes(region)) {
    return new Response('Access denied: WorkersProxy is not available in your region yet.', {
      status: 403
    });
  } 
  // 根据IP地址阻止访问
  else if (blocked_ip_address.includes(ip_address)) {
    return new Response('Access denied: Your IP address is blocked by WorkersProxy.', {
      status: 403
    });
  }

  // 判断设备类型，确定使用的上游服务器域名
  const is_desktop = await device_status(user_agent);
  const upstream_domain = is_desktop ? upstream : upstream_mobile;

  // 创建新的URL对象，并设置上游服务器域名
  let url = new URL(request.url);
  url.hostname = upstream_domain;

  // 如果指定了HTTPS协议，则设置协议为https
  url.protocol = https ? 'https:' : 'http:';

  // 修改请求头
  const modified_headers = new Headers(request.headers);
  modified_headers.set('Host', upstream_domain);
  modified_headers.set('Referer', request.url);

  console.log(`Fetching URL: ${url.href}`);  // 调试日志

  try {
    // 发送请求到上游服务器
    const response = await fetch(url.href, {
      method: request.method,
      headers: modified_headers
    });

    // 修改响应头
    const new_response_headers = new Headers(response.headers);
    new_response_headers.set('access-control-allow-origin', '*');
    new_response_headers.set('access-control-allow-credentials', 'true');
    new_response_headers.delete('content-security-policy');
    new_response_headers.delete('content-security-policy-report-only');
    new_response_headers.delete('clear-site-data');

    // 如果响应内容是HTML，进行内容替换
    const contentType = new_response_headers.get('content-type');
    if (contentType && contentType.includes('text/html')) {
      let text = await response.text();
      text = replaceInText(text, upstream_domain, url.hostname, url.origin + url.pathname);
      return new Response(text, {
        status: response.status,
        headers: new_response_headers
      });
    } 
    // 否则直接返回响应
    else {
      return new Response(response.body, {
        status: response.status,
        headers: new_response_headers
      });
    }
  } catch (error) {
    // 捕获并记录错误，返回500错误响应
    console.error(`Error fetching URL: ${url.href}`, error);
    return new Response('Internal Server Error', { status: 500 });
  }
}

// 替换文本内容中的特定字符串
function replaceInText(text, upstream_domain, host_name, base_url) {
  for (let i in replace_dict) {
    let j = replace_dict[i];
    if (i === '$upstream') i = upstream_domain;
    if (i === '$custom_domain') i = host_name;
    if (j === '$upstream') j = upstream_domain;
    if (j === '$custom_domain') j = host_name;
    let re = new RegExp(i, 'g');
    text = text.replace(re, j);
  }

  // 替换相对URL为绝对URL，避免路径问题
  text = text.replace(/(href|src)="([^"]*)"/g, function(match, p1, p2) {
    if (!p2.startsWith('http') && !p2.startsWith('//')) {
      return `${p1}="${new URL(p2, base_url).toString()}"`;
    }
    return match;
  });

  return text;
}

// 判断设备类型
async function device_status(user_agent_info) {
  const agents = ["Android", "iPhone", "SymbianOS", "Windows Phone", "iPad", "iPod"];
  for (let v = 0; v < agents.length; v++) {
    if (user_agent_info.indexOf(agents[v]) > 0) {
      return false;
    }
  }
  return true;
}
