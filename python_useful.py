import socket,struct,sys,time


#assume a socket disconnect (data returned is empty string) means  all data was #done being sent.
# from http://aspn.activestate.com/ASPN/Cookbook/Python/Recipe/408859


def recv_all_blockingly_return_zero_if_dead(the_socket):
    # returns '' if the socket is actually broken, so can continue to use this...happens to conglomerate everything together, which you may or may not want.
    the_socket.setblocking(1)
    total_data=[]
    while True:
        data = the_socket.recv(8192)
        if not data: break
        total_data.append(data)
    return ''.join(total_data)

def recv_anything_within_timeout(the_socket,timeout=2):
    the_socket.setblocking(0)
    total_data=[];data='';begin=time.time()
    while 1:

            data=the_socket.recv(8192) # non blocking
            if data:
                return data
            else:
                if time.time()-begin > timeout:
                    break
            time.sleep(0.1)

def recv_over_time_interval(the_socket,timeout=2):
    the_socket.setblocking(0)
    total_data=[];data='';begin=time.time()
    while 1:
        #if you got some data, then break after wait sec
        if total_data and time.time()-begin > timeout:
            break
        #if you got no data at all, wait a little longer
        elif time.time()-begin > timeout*2:
            break
        try:
            data=the_socket.recv(8192)
            if data:
                total_data.append(data)
                begin=time.time()
            else:
                time.sleep(0.1)
        except:
            pass
    return ''.join(total_data)

End='something useable as an end marker' # arbitrary "marker" you could put in your stream to deliniate chunks...

def recv_end(the_socket):
    total_data=[];data=''
    while True:
            data=the_socket.recv(8192)
            if End in data:
                total_data.append(data[:data.find(End)])
                break
            total_data.append(data)
            if len(total_data)>1:
                #check if end_of_data was split
                last_pair=total_data[-2]+total_data[-1]
                if End in last_pair:
                    total_data[-2]=last_pair[:last_pair.find(End)]
                    total_data.pop()
                    break
    return ''.join(total_data)

# unknown what this does.
def recv_size(the_socket):
    #data length is packed into 4 bytes
    total_len=0;total_data=[];size=sys.maxint
    size_data=sock_data='';recv_size=8192
    while total_len<size:
        sock_data=the_socket.recv(recv_size)
        if not total_data:
            if len(sock_data)>4:
                size_data+=sock_data
                size=struct.unpack('>i', size_data[:4])[0]
                recv_size=size
                if recv_size>524288:recv_size=524288
                total_data.append(size_data[4:])
            else:
                size_data+=sock_data
        else:
            total_data.append(sock_data)
        total_len=sum([len(i) for i in total_data ])
    return ''.join(total_data)


##############
def start_server(recv_type=''):
    sock=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    sock.bind(('',Port))
    sock.listen(5)
    print 'started on',Port
    while True:

        newsock,address=sock.accept()
        print 'connected'
        if recv_type=='size': result=recv_size(newsock)
        elif recv_type=='end': result=recv_end(newsock)
        elif recv_type=='timeout': result=recv_timeout(newsock)
        else: result=newsock.recv(8192) 
        print 'got',result


if __name__=='__main__':
    #start_server()
    #start_server(recv_type='size')
    #start_server(recv_type='timeout')
    start_server(recv_type='end')

def send_size(data):
    sock=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    sock.connect(('localhost',Port))
    sock.sendall(struct.pack('>i', len(data))+data)
    sock.close()

def send_end(data):
    sock=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
    sock.connect(('localhost',Port))
    sock.sendall(data+End)
    sock.close()
