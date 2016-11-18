<?php

/**
 * 
 * 聊天主逻辑
 * 主要是处理 onMessage onClose 
 * @author walkor < walkor@workerman.net >
 * 
 */
use \GatewayWorker\Lib\Gateway;
use \GatewayWorker\Lib\Store;
use \GatewayWorker\Lib\Db;

class Event {

    /**
     * 有消息时
     * @param int $client_id
     * @param string $message
     */
    public static function onMessage($client_id, $message) {
        // debug
        echo "client:{$_SERVER['REMOTE_ADDR']}:{$_SERVER['REMOTE_PORT']} gateway:{$_SERVER['GATEWAY_ADDR']}:{$_SERVER['GATEWAY_PORT']}  client_id:$client_id session:" . json_encode($_SESSION) . " onMessage:" . $message . "\n";

        // 客户端传递的是json数据
        $message_data = json_decode($message, true);
        if (!$message_data) {
            return;
        }

        // 根据类型执行不同的业务
        switch ($message_data['type']) {
            // 客户端回应服务端的心跳
            case 'pong':
                return;
            // 客户端登录 message格式: {type:login, name:xx, room_id:1} ，添加到客户端，广播给所有客户端xx进入聊天室
            case 'login':
         
			//SKIPER开始-------------------------------------------------------------------				
			case 'skiper_re_login':
				$db1 = Db::instance('skiper');
				$row = $db1->select('uid')->from('user')->where('uid = :uid')->bindValues(array('uid'=> $message_data['uid']))->row();
				if(!$row) return Gateway::sendToCurrentClient(json_encode(array('status'=> false,'msg'   => 'login failed')));
				self::delClientFromRoom($message_data['uid']);
				$all_clients = self::addClientToRoom($client_id, $message_data['uid']);
				
				//-----------------------------------------------------------聊天室判断
				// 判断是否有房间号
				if(isset($message_data['room_id'])){
					// 把房间号昵称放到session中
					$uid = $message_data['uid'];
					$room_id = explode(",", $message_data['room_id']);
					//return Gateway::sendToCurrentClient(json_encode( array('status'=> false, 'msg' => $room_id, 'type'  => 'message')) );
					//$_SESSION['room_id'] = $room_id;
					//$_SESSION['uid'] = $uid;
					foreach($room_id as $row){
						self::delClientFromRoom($uid,$row);
						// 存储到当前房间的客户端列表
						$all_clients = self::addClientToRoom( $client_id, $uid, $row );
					}
					/*// 整理客户端列表以便显示
					$client_list = self::formatClientsData($all_clients);
					// 转播给当前房间的所有客户端，xx进入聊天室 message {type:login, client_id:xx, name:xx}
					$new_message = array(
						'type'=>$message_data['type'], 'client_id'=>$client_id, 'client_name'=>htmlspecialchars($client_name), 'client_list'=>$client_list, 'time'=>date('Y - m - d H:i:s')
					);
					$client_id_array = array_keys($all_clients);
					Gateway::sendToAll(json_encode($new_message), $client_id_array);*/
				}		
				
				Gateway::sendToCurrentClient(json_encode(array('status'=>true, 'msg'=>'login success')));
				return;
				
			// 客户端发言 message: {type:say, to_client_id:xx, content:xx}
			case 'skiper_say':
				//return Gateway::sendToCurrentClient($message_data);
				// 私聊--------------------------------------------------------------------
				//return Gateway::sendToCurrentClient(json_encode($message_data));
				if($message_data['to_client_id'] != 'all'){
					$db1 = Db::instance('skiper');				
					$to_client_id = self::getClientId($message_data['to_client_id']);					
					$content      = $message_data['content'];
					$content['types'] = $content['types'] ? $content['types'] : 1;
					//$content['title'] = $content['title'] ? $content['title'] : '';
					//$content['img'] = $content['img'] ? $content['img'] : '';
					$content['content'] = nl2br(htmlspecialchars($content['content']));
					$uname		= $message_data['uname'];
					$tuname		= $message_data['rname'];
					$new_message = array(
						'type'          => 'skiper_say',
						'from_client_id'=> $message_data['from_client_id'],
						'to_client_id'  => $message_data['to_client_id'],
						'uname'			=> $uname,
						'uicon'			=> $message_data['uicon'],
						'content'       => $content,
						'time'          => time()
					);
					//insert into chat table
					$db1->insert('user_chat_log')->cols( array(
						'uid'			=>	$message_data['from_client_id'],
						'uname'			=>	$uname,
						'ruid'			=>	$message_data['to_client_id'],
						'rname'		=>	$tuname,
						'content'   	=> json_encode($content),
						'createtime'	=>	time()
					))->query();					
					Gateway::sendToClient($to_client_id, json_encode($new_message));
					return Gateway::sendToCurrentClient(json_encode(array('status'=>true, 'msg'=>'success', 'type'=>'message')));
				}
				break;	

			// 房间客户端发言 message: {type:say, to_client_id:xx, content:xx}
			case 'skiper_roomsay':
				// 非法请求
				$room_id = $message_data['room_id'];
				if(!$room_id){
					throw new \Exception("\$_SESSION['room_id'] not set. client_ip:{$_SERVER['REMOTE_ADDR']}");
				}
				// 私聊
				if($message_data['to_client_id'] != 'all') { }
				
				$all_clients = self::getClientListFromRoom($room_id);
				//print_r($all_clients);
				//return Gateway::sendToCurrentClient(json_encode(array('status'=> true, 'msg' => $all_clients."--".$room_id, 'type'  => 'message')));
				// 向大家说
				if($all_clients){
					$client_list = self::formatClientsData($all_clients);
					$client_id_array = array_keys($all_clients);
					//内容格式化
					$content = $message_data['content'];
					$content['types'] = $content['types'] ? $content['types'] : 1;
					//$content['title'] = isset($content['title']) ? $content['title'] : '';
					//$content['img'] = isset($content['img']) ? $content['img'] : '';
					$content['content'] = isset($content['content']) ? nl2br(htmlspecialchars($content['content'])) : '';
					$new_message = array(
						'type'          => 'skiper_roomsay',
						'from_client_id'=> $message_data['from_client_id'],
						'to_client_id'  => "all",
						'content'       => $content,
						'uname'			=> $message_data['uname'],
						'uicon'			=> $message_data['uicon'],
						'room_id'  => $room_id,
						'time'          => time()
					);
					
					$db1 = Db::instance('skiper');	
					//insert into chat table
					$db1->insert('circle_chat_log')->cols( array(
							'uid' => $message_data['from_client_id'],
							'circleid'  => $room_id,
							'content' => json_encode($content),
							'createtime'=>time()
						))->query();							
					//return Gateway::sendToCurrentClient(json_encode(array('status'=> true, 'msg' => $message_data['from_client_id'], 'type'  => 'message')));	
					Gateway::sendToAll(json_encode($new_message), $client_id_array);
					return Gateway::sendToCurrentClient( json_encode( array('status'=> true,'msg'=>'success' , 'type'=>'message') ) );
				}
				break;	
				
        }
    }

    /**
     * 当客户端断开连接时
     * @param integer $client_id 客户端id
     */
    public static function onClose($client_id) {
        // debug
        echo "client:{$_SERVER['REMOTE_ADDR']}:{$_SERVER['REMOTE_PORT']} gateway:{$_SERVER['GATEWAY_ADDR']}:{$_SERVER['GATEWAY_PORT']}  client_id:$client_id onClose:''\n";

        // 从房间的客户端列表中删除
        if (isset($_SESSION['room_id'])) {
            self::delClientFromRoom($client_id);
            // 广播 xxx 退出了
            if ($all_clients = self::getClientListFromRoom()) {
                $client_list = self::formatClientsData($all_clients);
                $new_message = array('type' => 'logout', 'from_client_id' => $client_id, 'from_client_name' => $_SESSION['client_name'], 'client_list' => $client_list, 'time' => date('Y-m-d H:i:s'));
                $client_id_array = array_keys($all_clients);
                Gateway::sendToAll(json_encode($new_message), $client_id_array);
            }
        }
    }

    /**
     * 格式化客户端列表数据
     * @param array $all_clients
     */
    public static function formatClientsData($all_clients) {
        $client_list = array();
        if ($all_clients) {
            foreach ($all_clients as $tmp_client_id => $tmp_name) {
                $client_list[] = array('client_id' => $tmp_client_id, 'client_name' => $tmp_name);
            }
        }
        return $client_list;
    }

    public static function getClientId($uid) {
        $list = self::getClientListFromRoom();
        foreach ($list as $k => $v) {
            if ($v == $uid) {
                return $k;
            }
        }
        return 0;
    }

    /**
     * 获得客户端列表
     * @todo 保存有限个
     */
    public static function getClientListFromRoom() {
        $key = "ROOM_CLIENT_LIST";
        $store = Store::instance('room');
        $ret = $store->get($key);
        if (false === $ret) {
            if (get_class($store) == 'Memcached') {
                if ($store->getResultCode() == \Memcached::RES_NOTFOUND) {
                    return array();
                } else {
                    throw new \Exception("getClientListFromRoom()->Store::instance('room')->get($key) fail " . $store->getResultMessage());
                }
            }
            return array();
        }
        return $ret;
    }

    /**
     * 从客户端列表中删除一个客户端
     * @param int $client_id
     */
    public static function delClientFromRoom($client_id) {
        $key = "ROOM_CLIENT_LIST";
        $store = Store::instance('room');
        // 存储驱动是memcached
        if (get_class($store) == 'Memcached') {
            $cas = 0;
            $try_count = 3;
            while ($try_count--) {
                $client_list = $store->get($key, null, $cas);
                if (false === $client_list) {
                    if ($store->getResultCode() == \Memcached::RES_NOTFOUND) {
                        return array();
                    } else {
                        throw new \Exception("Memcached->get($key) return false and memcache errcode:" . $store->getResultCode() . " errmsg:" . $store->getResultMessage());
                    }
                }
                if (isset($client_list[$client_id])) {
                    unset($client_list[$client_id]);
                    if ($store->cas($cas, $key, $client_list)) {
                        return $client_list;
                    }
                } else {
                    return true;
                }
            }
            throw new \Exception("delClientFromRoom($client_id)->Store::instance('room')->cas($cas, $key, \$client_list) fail" . $store->getResultMessage());
        }
        // 存储驱动是memcache或者file
        else {
            $handler = fopen(__FILE__, 'r');
            flock($handler, LOCK_EX);
            $client_list = $store->get($key);
            if (isset($client_list[$client_id])) {
                unset($client_list[$client_id]);
                $ret = $store->set($key, $client_list);
                flock($handler, LOCK_UN);
                return $client_list;
            }
            flock($handler, LOCK_UN);
        }
        return $client_list;
    }

    /**
     * 添加到客户端列表中
     * @param int $client_id
     * @param string $client_name
     */
    public static function addClientToRoom($client_id, $client_name) {
        $key = "ROOM_CLIENT_LIST";
        $store = Store::instance('room');
        // 获取所有所有房间的实际在线客户端列表，以便将存储中不在线用户删除
        $all_online_client_id = Gateway::getOnlineStatus();
        // 存储驱动是memcached
        if (get_class($store) == 'Memcached') {
            $cas = 0;
            $try_count = 3;
            while ($try_count--) {
                $client_list = $store->get($key, null, $cas);
                if (false === $client_list) {
                    if ($store->getResultCode() == \Memcached::RES_NOTFOUND) {
                        $client_list = array();
                    } else {
                        //throw new \Exception("Memcached->get($key) return false and memcache errcode:" . $store->getResultCode() . " errmsg:" . $store->getResultMessage());
			Gateway::sendToCurrentClient(json_encode(array('status' => false, 'msg' => 'login failed')));
			return;
                    }
                }
                if (!isset($client_list[$client_id])) {
                    // 将存储中不在线用户删除
                    if ($all_online_client_id && $client_list) {
                        $all_online_client_id = array_flip($all_online_client_id);
                        $client_list = array_intersect_key($client_list, $all_online_client_id);
                    }
                    // 添加在线客户端
                    $client_list[$client_id] = $client_name;
                    // 原子添加
                    if ($store->getResultCode() == \Memcached::RES_NOTFOUND) {
                        $store->add($key, $client_list);
                    }
                    // 置换
                    else {
                        $store->cas($cas, $key, $client_list);
                    }
                    if ($store->getResultCode() == \Memcached::RES_SUCCESS) {
                        return $client_list;
                    }
                } else {
                    return $client_list;
                }
            }
            //throw new \Exception("addClientToRoom($client_id, $client_name)->cas($cas, $key, \$client_list) fail ." . $store->getResultMessage());
		Gateway::sendToCurrentClient(json_encode(array('status' => false, 'msg' => 'login failed')));
		return;
        }
        // 存储驱动是memcache或者file
        else {
            $handler = fopen(__FILE__, 'r');
            flock($handler, LOCK_EX);
            $client_list = $store->get($key);
            if (!isset($client_list[$client_id])) {
                // 将存储中不在线用户删除
                if ($all_online_client_id && $client_list) {
                    $all_online_client_id = array_flip($all_online_client_id);
                    $client_list = array_intersect_key($client_list, $all_online_client_id);
                }
                // 添加在线客户端
                $client_list[$client_id] = $client_name;
                $ret = $store->set($key, $client_list);
                flock($handler, LOCK_UN);
                return $client_list;
            }
            flock($handler, LOCK_UN);
        }
        return $client_list;
    }

}